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
    expect(response.body).to include("0 chamado(s) encontrado(s)")
    get ti_operacao_path(chamado)
    expect(response).to have_http_status(:not_found)
  end

  context "com técnico do grupo" do
    before { sign_in tecnico }

    it "lista os chamados sem responsável, com busca, e as outras visões" do
      get ti_operacao_index_path
      expect(response.body).to include("1 chamado(s) encontrado(s)", chamado.codigo, "SEM INTERNET", "MARIA OLIVEIRA", "NUINFO - NÚCLEO DE INFORMÁTICA", "Assumir chamado")

      get ti_operacao_index_path, params: { q: "maria", status: "meus" }
      expect(response.body).to include("0 chamado(s) encontrado(s)")

      post acao_ti_operacao_path(chamado, "assumir")
      get ti_operacao_index_path, params: { status: "meus" }
      expect(response.body).to include("1 chamado(s) encontrado(s)", "Em trabalho", "JOAO TECNICO")
    end

    it "a linha da lista traz as ações que cabem a ele em cada etapa; ver é só leitura, no painel" do
      acoes_da_linha = -> { Nokogiri::HTML(response.body).css("tbody td:last-child [title]").pluck("title") }

      get ti_operacao_index_path
      expect(acoes_da_linha.call).to eq([ "Visualizar chamado", "Assumir chamado" ])

      post acao_ti_operacao_path(chamado, "assumir")
      expect(response).to redirect_to(ti_operacao_index_path)
      get ti_operacao_index_path, params: { status: "meus" }
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
