require "rails_helper"

# Telas de Movimentações, Empréstimos e cautelas, Meus equipamentos e Histórico.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe "Equipamentos: envios, recebimentos e histórico" do
  let(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let(:asjur) { create(:rh_unidade, nome: "Assessoria Jurídica", sigla: "ASJUR") }
  let(:gestor) { usuario_de_equipamentos("GESTOR DO NUINFO", unidade: nuinfo, papel: "gestor") }
  let(:colega) { usuario_de_equipamentos("COLEGA DO NUINFO", unidade: nuinfo) }
  let(:maria) { usuario_de_equipamentos("MARIA OLIVEIRA", unidade: asjur) }
  let(:admin) { usuario_de_equipamentos("ADMIN DE EQUIPAMENTOS", papel: "admin") }
  let!(:monitor) { create(:equipamentos_item, unidade: nuinfo, numero_patrimonio: "PAT001", codigo_kit: "KIT-000001", identificacao_kit: "MESA 5") }
  let!(:teclado) { create(:equipamentos_item, unidade: nuinfo, tipo_equipamento: "Teclado", numero_patrimonio: "PAT002", codigo_kit: "KIT-000001", identificacao_kit: "MESA 5") }
  let(:painel) { { "Turbo-Frame" => "painel" } }

  def enviar(tipo: "movimentacao", itens: [ monitor, teclado ], **outros)
    Equipamentos::Envios::Criar.call(tipo: tipo, origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: maria.id, item_ids: itens.map(&:id), criada_por: gestor, **outros).objeto
  end

  def emprestar(**outros) = enviar(tipo: "emprestimo", previsao_devolucao: 10.days.from_now.to_date, **outros)
  def pagina = Nokogiri::HTML(response.body)
  def codigos = pagina.css("tbody tr[id] td:first-child a").map { |link| link.text.strip }
  def acoes(envio) = pagina.css("tr##{ActionView::RecordIdentifier.dom_id(envio)} td:last-child [title]").pluck("title")
  def erro = pagina.css("[data-faixa-aviso='erro']").text.squish

  describe "movimentações" do
    before { sign_in gestor }

    it "o formulário mostra os equipamentos da origem, com o atalho do kit, e só as pessoas do destino" do
      preso = create(:equipamentos_item, unidade: nuinfo, tipo_equipamento: "Mouse", numero_patrimonio: "PAT003")
      enviar(itens: [ preso ])
      create(:equipamentos_item, unidade: asjur, numero_patrimonio: "PAT900")

      get new_equipamentos_movimentacao_path(item_ids: [ monitor.id ], envio: { destino_id: asjur.id }), headers: painel

      expect(response.body).to include("Nova movimentação", 'value="NUINFO - NÚCLEO DE INFORMÁTICA"', "Kit inteiro", "Kit MESA 5", "Só aparecem as pessoas lotadas em ASJUR")
      expect(pagina.css("input[name='envio[item_ids][]']").map { |caixa| [ caixa["value"].to_i, caixa["checked"].present?, caixa["disabled"].present? ] })
        .to contain_exactly([ monitor.id, true, false ], [ teclado.id, false, false ], [ preso.id, false, true ])
      expect(response.body).not_to include("PAT900")
      maria
      get equipamentos_opcoes_de_pessoas_path(unidade_id: asjur.id), as: :json
      expect(response.parsed_body["opcoes"].pluck("rotulo")).to eq([ "MARIA OLIVEIRA" ])
    end

    it "envia e mostra na lista, com as ações na linha" do
      post equipamentos_movimentacoes_path, params: { envio: { origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: maria.id, item_ids: [ monitor.id, teclado.id ], descricao: "Troca de sala" } }

      envio = Equipamentos::Movimentacao.sole
      expect(response).to redirect_to(equipamentos_movimentacoes_path)
      get equipamentos_movimentacoes_path
      expect(codigos).to eq([ envio.codigo ])
      expect(response.body).to include("→ ASJUR - ASSESSORIA JURÍDICA", "MARIA OLIVEIRA", "2 equipamento(s)", "2 aguardando recebimento")
      expect(acoes(envio)).to eq([ "Visualizar envio", "Cancelar envio de equipamento" ])
    end

    it "quem criou cancela um equipamento ainda não recebido, ou todos os pendentes" do
      envio = enviar

      get cancelamento_equipamentos_movimentacao_path(envio), headers: painel
      expect(response.body).to include("Cancelar todos os pendentes", "Cancelar este")
      patch cancelar_equipamentos_movimentacao_path(envio), params: { item_id: monitor.id }
      expect([ monitor.reload.situacao, teclado.reload.situacao, envio.reload.status ]).to eq(%w[disponivel em_movimentacao em_andamento])
      patch cancelar_equipamentos_movimentacao_path(envio)
      expect(envio.reload.status).to eq("cancelada")
      get equipamentos_movimentacoes_path(status: "cancelada")
      expect(codigos).to eq([ envio.codigo ])
    end

    it "recusa com a mensagem no próprio formulário (422) e mantém o que foi preenchido" do
      post equipamentos_movimentacoes_path, params: { envio: { origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: colega.id, item_ids: [ monitor.id ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(erro).to eq("COLEGA DO NUINFO não está lotado(a) em ASJUR - ASSESSORIA JURÍDICA.")
      expect(pagina.at_css("#envio_item_#{monitor.id}")["checked"]).to be_present
    end

    it "busca por código, pessoa ou equipamento e junta tudo na aba Resultado" do
      envio = enviar
      Equipamentos::Envios::Operar.call(envio: envio, acao: "receber_item", ator: maria)

      achados = [ {}, { q: "pat002" }, { q: "maria oliv" }, { q: "nada disso" }, { status: "concluida" } ].map { |filtro| get(equipamentos_movimentacoes_path(filtro)) && codigos }

      expect(achados).to eq([ [], [ envio.codigo ], [ envio.codigo ], [], [ envio.codigo ] ])
      get equipamentos_movimentacoes_path(q: "pat002")
      expect(response.body).to include("Resultado", "Concluída")
    end

    it "ver abre no painel, só leitura" do
      envio = enviar

      get equipamentos_movimentacao_path(envio)
      expect(response).to redirect_to("#{equipamentos_movimentacoes_path(status: 'em_andamento')}&painel=#{CGI.escape(equipamentos_movimentacao_path(envio))}")
      get equipamentos_movimentacao_path(envio), headers: painel
      expect(response.body).to include("Movimentação #{envio.codigo}", "Aguardando recebimento", "Fechar")
    end

    it "o gestor de outra unidade não vê o envio; quem só recebe não entra nas listas" do
      envio = enviar
      sign_in usuario_de_equipamentos("GESTORA DO CEFOR", unidade: create(:rh_unidade, nome: "Centro de Formação", sigla: "CEFOR"), papel: "gestor")
      get equipamentos_movimentacoes_path
      expect(codigos).to be_empty
      get equipamentos_movimentacao_path(envio), headers: painel
      expect(response).to have_http_status(:not_found)

      sign_in maria
      get equipamentos_movimentacoes_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "meus equipamentos" do
    it "quem recebe dá o recebido de cada equipamento, ou de todos" do
      envio = enviar
      sign_in maria

      get equipamentos_recebimentos_path
      expect(response.body).to include("Para receber", "Receber todos (2)", "Monitor DELL P2419H", "PAT002", "enviado por GESTOR DO NUINFO")
      patch receber_equipamentos_recebimento_path(envio), params: { item_id: monitor.id }
      expect(response).to redirect_to(equipamentos_recebimentos_path)
      expect(monitor.reload).to have_attributes(rh_unidade_id: asjur.id, situacao: "disponivel")
      patch receber_equipamentos_recebimento_path(envio)
      expect([ teclado.reload.rh_unidade_id, envio.reload.status ]).to eq([ asjur.id, "concluida" ])
      get equipamentos_recebimentos_path
      expect(response.body).to include("Você não tem equipamento para receber, aceitar ou devolver.")
    end

    it "empréstimo: quem recebe abre o termo e aceita" do
      envio = emprestar
      sign_in maria

      get equipamentos_recebimentos_path
      expect(response.body).to include("Empréstimos e cautelas para aceitar", "Abrir o termo")
      get termo_equipamentos_recebimento_path(envio), headers: painel
      expect(response.body).to include("TERMO DE RESPONSABILIDADE", "Li e aceito o termo", "patrimônio PAT001")
      patch aceitar_equipamentos_recebimento_path(envio)
      expect(monitor.reload).to have_attributes(situacao: "emprestado", posse_rh_unidade_id: asjur.id, rh_unidade_id: nuinfo.id)
      get equipamentos_recebimentos_path
      expect(response.body).to include("Comigo (emprestados)", "Devolver", "Ver o termo")
    end

    it "devolve indicando alguém da unidade de origem, e pode trocar a pessoa enquanto ninguém recebeu" do
      envio = emprestar.tap { |novo| Equipamentos::Envios::Operar.call(envio: novo, acao: "aceitar", ator: maria) }
      sign_in maria

      get devolucao_equipamentos_recebimento_path(envio), headers: painel
      expect(response.body).to include("Quem recebe na unidade de origem", "Iniciar devolução")
      patch devolver_equipamentos_recebimento_path(envio), params: { para_id: maria.id }
      expect([ response.status, erro ]).to match([ 422, /não está lotado\(a\) em NUINFO/ ])
      patch devolver_equipamentos_recebimento_path(envio), params: { para_id: colega.id }
      get devolucao_equipamentos_recebimento_path(envio), headers: painel
      expect(response.body).to include("aguardando COLEGA DO NUINFO", "Trocar quem recebe")
      patch devolver_equipamentos_recebimento_path(envio), params: { para_id: gestor.id }
      expect(envio.reload.itens.map(&:devolver_para).uniq).to eq([ gestor ])
    end

    it "a pessoa indicada vê o termo aceito e confirma o recebimento, com observação" do
      envio = emprestar.tap do |novo|
        Equipamentos::Envios::Operar.call(envio: novo, acao: "aceitar", ator: maria)
        Equipamentos::Envios::Operar.call(envio: novo.reload, acao: "devolver", ator: maria, para_id: gestor.id)
      end
      sign_in colega
      get equipamentos_recebimentos_path
      expect(response.body).not_to include("Devoluções para eu receber")

      sign_in gestor
      get equipamentos_recebimentos_path
      expect(response.body).to include("Devoluções para eu receber", "MARIA OLIVEIRA (ASJUR - ASSESSORIA JURÍDICA) está devolvendo 2 equipamento(s)")
      get recebimento_da_devolucao_equipamentos_recebimento_path(envio), headers: painel
      expect(response.body).to include("Termo aceito por MARIA OLIVEIRA", "TERMO DE RESPONSABILIDADE", "Confirmar o recebimento")
      patch receber_devolucao_equipamentos_recebimento_path(envio), params: { observacao: "Sem o cabo de força" }
      expect(monitor.reload).to have_attributes(situacao: "disponivel", posse_rh_unidade_id: nil)
      expect([ envio.reload.status, envio.itens.map(&:observacao_da_devolucao).uniq ]).to eq([ "concluida", [ "Sem o cabo de força" ] ])
    end

    it "ninguém mexe no envio dos outros" do
      envio = emprestar
      sign_in colega

      get termo_equipamentos_recebimento_path(envio), headers: painel
      expect(response).to have_http_status(:not_found)
      sign_in colega # o erro acima encerra a sessão do teste
      patch aceitar_equipamentos_recebimento_path(envio)
      expect(response).to have_http_status(:not_found)
      expect(envio.reload).not_to be_aceita
    end

    it "o administrador dá o recebido em nome de quem recebe, pela lista, e fica registrado" do
      movimentacao = enviar(itens: [ monitor ])
      sign_in admin

      get equipamentos_movimentacoes_path
      expect(acoes(movimentacao)).to eq([ "Visualizar envio", "Cancelar envio de equipamento", "Dar o recebido em nome de MARIA OLIVEIRA" ])
      patch receber_equipamentos_recebimento_path(movimentacao, voltar: "lista")
      expect(response).to redirect_to(equipamentos_movimentacoes_path)
      expect(monitor.eventos.order(:id).last.nota).to include("feito por ADMIN DE EQUIPAMENTOS, administrador, em nome de MARIA OLIVEIRA")
    end

    it "o administrador aceita o termo em nome de quem recebe" do
      emprestimo = emprestar(itens: [ teclado ])
      sign_in admin

      get equipamentos_emprestimos_path
      expect(acoes(emprestimo)).to include("Aceitar o termo em nome de MARIA OLIVEIRA")
      get termo_equipamentos_recebimento_path(emprestimo, voltar: "lista"), headers: painel
      expect(response.body).to include("Aceitar em nome de MARIA OLIVEIRA", "Você está aceitando como administrador")
      patch aceitar_equipamentos_recebimento_path(emprestimo), params: { voltar: "lista" }
      expect(response).to redirect_to(equipamentos_emprestimos_path)
      expect(teclado.reload.situacao).to eq("emprestado")
    end
  end

  describe "empréstimos e cautelas" do
    before { sign_in gestor }

    it "pede o tipo e a devolução prevista" do
      get new_equipamentos_emprestimo_path, headers: painel
      expect(response.body).to include("Novo empréstimo ou cautela", "Devolução prevista *", "Cautela")
      post equipamentos_emprestimos_path, params: { envio: { tipo: "cautela", origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: maria.id, item_ids: [ monitor.id ] } }
      expect(erro).to include("Data prevista de devolução deve ser preenchida")
      post equipamentos_emprestimos_path, params: { envio: { tipo: "cautela", origem_id: nuinfo.id, destino_id: asjur.id, responsavel_id: maria.id, item_ids: [ monitor.id ],
                                                             previsao_devolucao: I18n.l(5.days.from_now.to_date) } }

      envio = Equipamentos::Movimentacao.sole
      expect(envio).to have_attributes(tipo: "cautela", codigo: "EM-#{format('%06d', envio.id)}", previsao_devolucao: 5.days.from_now.to_date)
    end

    it "mostra com quem está, há quantos dias e o atraso em vermelho; não se mistura com as movimentações" do
      envio = emprestar(itens: [ monitor ]).tap { |novo| Equipamentos::Envios::Operar.call(envio: novo, acao: "aceitar", ator: maria) }
      envio.update_columns(aceita_em: 20.days.ago, previsao_devolucao: 3.days.ago.to_date)
      no_prazo = emprestar(itens: [ teclado ])

      get equipamentos_emprestimos_path
      expect(response.body).to include("Empréstimo", "20 dia(s) emprestado", "Atrasado 3 dias", "1 emprestado")
      expect(codigos).to contain_exactly(envio.codigo, no_prazo.codigo)
      get equipamentos_emprestimos_path(atrasados: "1")
      expect(codigos).to eq([ envio.codigo ])
      get equipamentos_movimentacoes_path
      expect(codigos).to be_empty
    end
  end

  describe "histórico" do
    before do
      Equipamentos::Itens::Salvar.call(item: monitor, atributos: { marca: "LG" }, salvo_por: gestor)
      create(:equipamentos_item, unidade: asjur, numero_patrimonio: "PAT900").registrar_evento("cadastrado", admin, "Cadastrado em ASJUR.")
      enviar(itens: [ teclado ])
    end

    def linhas = pagina.css("tbody tr[id] td:nth-child(3) p:first-child").map { |celula| celula.text.strip }

    it "mostra o que aconteceu com os equipamentos da unidade, com o antes e o depois de cada alteração" do
      sign_in gestor

      get equipamentos_historico_path

      expect(linhas).to eq([ "Envio para outra unidade", "Alteração" ])
      expect(response.body).to include("Marca: DELL → LG", "GESTOR DO NUINFO")
      expect(response.body).not_to include("Cadastrado em ASJUR")
    end

    it "é pesquisável pelo que mudou, pelo equipamento, pelo tipo e pela data; quem só recebe não entra" do
      sign_in gestor

      achados = [ { q: "dell → lg" }, { q: "pat002", tipo: "movimentacao_criada" }, { q: "gestor do nuinfo", tipo: "editado" }, { de: I18n.l(Date.tomorrow) } ]
                .map { |filtro| get(equipamentos_historico_path(filtro)) && linhas }

      expect(achados).to eq([ [ "Alteração" ], [ "Envio para outra unidade" ], [ "Alteração" ], [] ])
      sign_in maria
      get equipamentos_historico_path
      expect(response).to have_http_status(:forbidden)
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
