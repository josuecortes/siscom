require "rails_helper"

RSpec.describe "TI: operação" do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: papel) }

  let(:redes) { create(:ti_grupo_tecnico, nome: "Redes") }
  let(:solicitacao) { create(:ti_problema, nome: "Sem internet", exige_triagem: false).tap { |p| p.grupos_tecnicos << redes } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:tecnico) { com_papel("tecnico", "JOAO TECNICO").tap { |u| redes.vinculos_de_membro.create!(user: u) } }
  let!(:chamado) do
    Ti::Chamado.create!(problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current,
                        unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA")
  end

  it "usuário comum não entra na operação" do
    sign_in maria

    respostas = [ -> { get ti_operacao_index_path }, -> { get ti_operacao_path(chamado) }, -> { post acao_ti_operacao_path(chamado, "assumir") } ]
                .map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
    expect(chamado.reload.status).to eq("aberto")
  end

  it "técnico de outro grupo não vê nem mexe no chamado" do
    sign_in com_papel("tecnico", "DE FORA")

    get ti_operacao_index_path
    expect(response.body).to include("0 chamado(s) que ninguém assumiu ainda")
    get ti_operacao_path(chamado)
    expect(response).to have_http_status(:not_found)
  end

  context "com técnico do grupo" do
    before { sign_in tecnico }

    def abas = Nokogiri::HTML(response.body).css("nav[aria-label='Etapas dos chamados'] a, nav[aria-label='Etapas dos chamados'] [aria-current]").map { |aba| aba.text.squish }.uniq
    def codigos = Nokogiri::HTML(response.body).css("tbody tr[id] td:first-child").map { |celula| celula.text.strip }

    it "Solicitadas mostra o que ninguém assumiu, já com o botão de assumir; abrir para outra pessoa fica aqui, não no menu" do
      get ti_operacao_index_path

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("1 chamado(s) que ninguém assumiu ainda", chamado.codigo, "SEM INTERNET", "MARIA OLIVEIRA", "NUINFO - NÚCLEO DE INFORMÁTICA", "Assumir chamado")
      expect(abas).to eq([ "Solicitadas 1", "Em triagem 0", "Em atendimento 0", "Parados 0", "Concluídos 0", "Finalizados 0", "Cancelados 0" ])
      expect(html.at_css("main a[title='Abrir para outra pessoa']")["href"]).to eq(new_ti_chamado_para_outro_path)
      expect(html.css("#menu-lateral a").map { |link| link.text.squish }).not_to include("Abrir para outra pessoa")
      expect(html.at_css("[role='switch']")).to be_nil # em Solicitadas aparece tudo: o liga/desliga não se aplica
    end

    it "nas outras abas vejo só os meus; ligando Ver os de todos vejo os dos outros, sem poder mexer neles" do
      pedro = com_papel("tecnico", "PEDRO TECNICO").tap { |user| redes.vinculos_de_membro.create!(user: user) }
      do_pedro = Ti::Chamado.create!(problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: Time.current)
      Ti::Chamados::Operar.call(chamado: do_pedro, acao: "assumir", ator: pedro)
      post acao_ti_operacao_path(chamado, "assumir")

      get ti_operacao_index_path, params: { status: "em_atendimento" }
      so_meus = [ codigos, abas[2], Nokogiri::HTML(response.body).at_css("[role='switch']")["aria-checked"] ]
      get ti_operacao_index_path, params: { status: "em_atendimento", de: "todos" }
      html = Nokogiri::HTML(response.body)

      expect(so_meus).to eq([ [ chamado.codigo ], "Em atendimento 1", "false" ])
      expect([ codigos, abas[2], html.at_css("[role='switch']")["aria-checked"] ]).to eq([ [ chamado.codigo, do_pedro.codigo ], "Em atendimento 2", "true" ])
      expect(html.css("tr##{ActionView::RecordIdentifier.dom_id(do_pedro)} td:last-child [title]").pluck("title")).to eq([ "Visualizar chamado" ])
      expect(response.body).to include("2 chamado(s) em em atendimento, de todos")
    end

    it "com filtro, as abas viram Resultado, com tudo o que enxergo; filtra por texto, categoria, unidade e data de abertura" do
      post acao_ti_operacao_path(chamado, "assumir")
      resultado = ->(filtros) { get(ti_operacao_index_path, params: filtros) && codigos }

      expect(resultado.call(q: "maria")).to eq([ chamado.codigo ])
      expect([ abas, response.body.include?("1 chamado(s) encontrado(s), de todas as etapas") ]).to eq([ [ "Resultado 1" ], true ])
      expect([ resultado.call(categoria_id: solicitacao.categoria_id), resultado.call(categoria_id: 0), resultado.call(unidade_id: chamado.rh_unidade_id || 0),
               resultado.call(aberto_de: I18n.l(Date.current)), resultado.call(aberto_ate: I18n.l(Date.yesterday)) ])
        .to eq([ [ chamado.codigo ], [], (chamado.rh_unidade_id ? [ chamado.codigo ] : []), [ chamado.codigo ], [] ])
      get ti_opcoes_de_unidades_path
      expect(response.parsed_body).to include("opcoes", "todas")
    end

    it "a busca acha pelo nome do solicitante, do técnico ou do triador; dá para escolher em qual deles procurar" do
      ana = com_papel("triagem", "ANA TRIADORA").tap { |user| redes.vinculos_de_membro.create!(user: user) }
      chamado.update!(responsavel: tecnico, triador: ana, status: "em_atendimento")
      outro = Ti::Chamado.create!(problema: solicitacao, solicitante: tecnico, solicitante_nome: tecnico.nome, solicitante_email: tecnico.email, aberto_em: Time.current)
      resultado = ->(q, pessoa = nil) { get(ti_operacao_index_path, params: { q: q, pessoa: pessoa }.compact) && codigos.sort }

      expect([ resultado.call("joao"), resultado.call("ana tri"), resultado.call("maria") ]).to eq([ [ chamado.codigo, outro.codigo ].sort, [ chamado.codigo ], [ chamado.codigo ] ])
      expect([ resultado.call("joao", "solicitante"), resultado.call("joao", "tecnico"), resultado.call("joao", "triador"), resultado.call("ana", "triador") ])
        .to eq([ [ outro.codigo ], [ chamado.codigo ], [], [ chamado.codigo ] ])
      expect(Nokogiri::HTML(response.body).css("select[name='pessoa'] option").map(&:text)).to eq([ "Solicitante, técnico ou triador", "Solicitante", "Técnico", "Triador" ])
    end

    it "chamado liberado volta para Solicitadas com o selo Liberado e a contagem de vezes" do
      pedro = com_papel("tecnico", "PEDRO TECNICO").tap { |user| redes.vinculos_de_membro.create!(user: user) }
      Ti::Chamados::Operar.call(chamado: chamado, acao: "assumir", ator: tecnico)
      Ti::Chamados::Operar.call(chamado: chamado.reload, acao: "liberar", ator: tecnico, nota: "Saio de férias.")
      get ti_operacao_index_path
      uma_vez = Nokogiri::HTML(response.body).at_css("tr##{ActionView::RecordIdentifier.dom_id(chamado)} td:nth-child(2) span[title]")

      Ti::Chamados::Operar.call(chamado: chamado.reload, acao: "assumir", ator: pedro)
      Ti::Chamados::Operar.call(chamado: chamado.reload, acao: "liberar", ator: pedro, nota: "Não é da minha área.")
      get ti_operacao_index_path
      duas_vezes = Nokogiri::HTML(response.body).at_css("tr##{ActionView::RecordIdentifier.dom_id(chamado)} td:nth-child(2) span[title]")

      expect([ uma_vez.text.squish, duas_vezes.text.squish ]).to eq([ "Liberado 1×", "Liberado 2×" ])
      expect(duas_vezes["title"]).to start_with("Estava sendo atendido e foi liberado 2 vezes. Última: PEDRO TECNICO em ")
      expect(response.body).to include("Assumir chamado") # quem pode pegar já vê o botão ao lado
    end

    it "a ordem troca pelo cabeçalho Aberto em; o padrão é o mais urgente primeiro" do
      urgente = Ti::Chamado.create!(problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: 1.minute.from_now, prioridade: "urgente")

      get ti_operacao_index_path
      padrao = codigos
      get ti_operacao_index_path, params: { ordem: "aberto" }
      mais_antigo = codigos
      get ti_operacao_index_path, params: { ordem: "aberto", direcao: "desc" }

      expect([ padrao, mais_antigo, codigos ]).to eq([ [ urgente.codigo, chamado.codigo ], [ chamado.codigo, urgente.codigo ], [ urgente.codigo, chamado.codigo ] ])
      expect(Nokogiri::HTML(response.body).at_css("th[aria-sort]")["aria-sort"]).to eq("descending")
    end

    it "a linha da lista traz as ações que cabem a ele em cada etapa; ver é só leitura, no painel" do
      acoes_da_linha = -> { Nokogiri::HTML(response.body).css("tbody td:last-child [title]").pluck("title") }

      get ti_operacao_index_path
      expect(acoes_da_linha.call).to eq([ "Visualizar chamado", "Assumir chamado" ])

      post acao_ti_operacao_path(chamado, "assumir")
      expect(response).to redirect_to(ti_operacao_index_path)
      get ti_operacao_index_path, params: { status: "em_atendimento" }
      expect(acoes_da_linha.call).to eq([ "Visualizar chamado", "Abrir conversa", "Mudar etapa", "Mudar prioridade" ])

      ver_no_painel ti_operacao_path(chamado)
      expect(response.body).to include("Chamado #{chamado.codigo}", "Chamado assumido para atendimento por JOAO TECNICO.")
      expect(response.body).not_to include("Concluir atendimento", "O que fazer")
    end

    it "Mudar etapa mostra as mudanças possíveis, e cada uma abre o painel da ação" do
      get etapa_ti_operacao_path(chamado)
      expect(response).to have_http_status(:forbidden) # ninguém assumiu: não há etapa para mudar

      post acao_ti_operacao_path(chamado, "assumir")
      get etapa_ti_operacao_path(chamado)

      opcoes = Nokogiri::HTML(response.body).css("#etapas_do_chamado a")
      expect(opcoes.map { |opcao| opcao.text.squish }).to eq([ "Pedir ajuste ao solicitante", "Marcar impedimento", "Concluir atendimento", "Liberar chamado" ])
      expect(opcoes.map { |opcao| opcao["href"] }).to include(acao_ti_operacao_path(chamado, "concluir"))
    end

    it "conclui pelo painel, exigindo o resultado do atendimento" do
      post acao_ti_operacao_path(chamado, "assumir")

      get acao_ti_operacao_path(chamado, "concluir")
      expect(response.body).to include("Concluir atendimento", "Resultado do atendimento *")

      post acao_ti_operacao_path(chamado, "concluir"), params: { nota: " " }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Resultado do atendimento deve ser preenchido.")

      post acao_ti_operacao_path(chamado, "concluir"), params: { nota: "Cabo trocado." }
      expect(chamado.reload.status).to eq("concluido")
    end

    it "não abre o painel de uma ação que não cabe a ele" do
      get acao_ti_operacao_path(chamado, "atribuir")
      expect(response).to have_http_status(:forbidden)

      post acao_ti_operacao_path(chamado, "reabrir"), params: { nota: "x" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "o supervisor atribui a um membro do grupo e muda a prioridade" do
    tecnico
    sign_in com_papel("supervisor", "SUPERVISOR")

    get acao_ti_operacao_path(chamado, "atribuir")
    expect(response.body).to include("Atribuir a *", "JOAO TECNICO")

    post acao_ti_operacao_path(chamado, "atribuir"), params: { alvo_id: tecnico.id, nota: "Você conhece a sala." }
    post acao_ti_operacao_path(chamado, "prioridade"), params: { prioridade: "critica", nota: "Gabinete parado." }

    expect(chamado.reload).to have_attributes(status: "em_atendimento", responsavel: tecnico, prioridade: "critica")
  end

  describe "resposta do solicitante" do
    before do
      Ti::Chamados::Operar.call(chamado: chamado, acao: "assumir", ator: tecnico)
      Ti::Chamados::Operar.call(chamado: chamado.reload, acao: "devolver", ator: tecnico, nota: "Qual é a sala?")
      sign_in maria
    end

    it "vê o pedido de ajuste no chamado e responde pelo painel" do
      ver_no_painel ti_chamado_path(chamado)
      expect(response.body).to include("A TI pediu um ajuste ao solicitante: Qual é a sala?")
      get ti_chamados_path, params: { status: "aguardando_solicitante" }
      expect(response.body).to include("Responder à TI", "Corrigir os dados e reenviar")

      patch responder_ti_chamado_path(chamado), params: { nota: "" }
      sem_resposta = response.status
      patch responder_ti_chamado_path(chamado), params: { nota: "Sala 12." }
      expect([ sem_resposta, chamado.reload.status ]).to eq([ 422, "em_atendimento" ])
      ver_no_painel ti_chamado_path(chamado)
      expect(response.body).to include("Solicitante respondeu: Sala 12.")
      expect(response.body).not_to include("A TI pediu um ajuste")
    end
  end
end
