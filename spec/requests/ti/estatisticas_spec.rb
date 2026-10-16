require "rails_helper"

RSpec.describe "TI: relatórios (estatísticas)" do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: papel) }

  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:joao) { com_papel("tecnico", "JOAO TECNICO") }
  let(:redes) { create(:ti_categoria, nome: "Rede") }
  let(:internet) { create(:ti_problema, nome: "Sem internet", categoria: redes) }
  let(:impressora) { create(:ti_problema, nome: "Impressora parada", categoria: create(:ti_categoria, nome: "Hardware")) }

  def chamado(solicitacao, aberto_em, **outros)
    Ti::Chamado.create!({ problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, aberto_em: aberto_em, unidade_nome: "NUINFO" }.merge(outros))
  end

  before do
    travel_to Time.zone.local(2026, 10, 5, 10, 0)
    chamado(internet, Time.zone.local(2026, 9, 10, 9, 0), status: "finalizado", responsavel: joao, concluido_em: Time.zone.local(2026, 9, 10, 11, 0), avaliacao: 5)
    chamado(internet, Time.zone.local(2026, 9, 30, 22, 30), status: "concluido", responsavel: joao, concluido_em: Time.zone.local(2026, 10, 1, 2, 30), unidade_nome: "ASJUR")
    chamado(impressora, Time.zone.local(2026, 10, 2, 8, 0), status: "cancelado")
    chamado(impressora, Time.zone.local(2026, 10, 3, 8, 0))
    chamado(internet, Time.zone.local(2024, 1, 5, 8, 0), status: "finalizado", responsavel: joao, avaliacao: 1) # fora do período padrão (último ano)
  end

  def secao(chave, **filtros) = Ti::Estatisticas::Consultar.call(filtros: filtros).secoes.find { |item| item.chave == chave }.linhas

  it "resume o período e separa por mês (no horário local), categoria, solicitação, unidade e técnico" do
    resultado = Ti::Estatisticas::Consultar.call

    expect(resultado.resumo).to eq("Chamados abertos no período" => 4, "Atendidos (concluídos e finalizados)" => 2, "Em andamento" => 1, "Cancelados" => 1,
                                   "Tempo médio até concluir" => "3 h 0 min", "Avaliação média (1 a 5)" => 5.0)
    expect(secao("mes")).to eq([ [ "09/2026", 2, 2, 0 ], [ "10/2026", 2, 0, 1 ] ])
    expect([ secao("categoria"), secao("solicitacao") ]).to eq([ [ [ "HARDWARE", 2 ], [ "REDE", 2 ] ], [ [ "IMPRESSORA PARADA", 2 ], [ "SEM INTERNET", 2 ] ] ])
    expect(secao("unidade")).to eq([ [ "NUINFO", 3 ], [ "ASJUR", 1 ] ])
    expect(secao("tecnico")).to eq([ [ "JOAO TECNICO", 2, 2, "3 h 0 min", 5.0 ] ])
  end

  it "filtra por período, categoria e técnico" do
    expect(secao("mes", inicio: "01/01/2024", fim: "31/12/2024")).to eq([ [ "01/2024", 1, 1, 0 ] ])
    expect(secao("solicitacao", categoria_id: redes.id)).to eq([ [ "SEM INTERNET", 2 ] ])
    expect(secao("tecnico", tecnico_id: joao.id, inicio: "01/01/2024")).to eq([ [ "JOAO TECNICO", 3, 3, "3 h 0 min", 3.0 ] ])
  end

  it "o supervisor vê a tela, procura o técnico e exporta o Excel; o técnico não entra" do
    sign_in com_papel("supervisor", "SUPERVISOR")

    get ti_estatisticas_path
    expect(response.body).to include("Relatórios", "Chamados abertos de 06/10/2025 a 05/10/2026", "Por mês de abertura", "Solicitações mais pedidas", "JOAO TECNICO", "Exportar Excel")
    get tecnicos_ti_estatisticas_path, params: { q: "joa" }
    expect(response.parsed_body["opcoes"].pluck("rotulo")).to eq([ "JOAO TECNICO" ])
    get ti_estatisticas_path(format: :xlsx)
    expect([ response.media_type, response.body[0, 2] ]).to eq([ "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "PK" ])

    sign_in joao
    get ti_estatisticas_path
    expect(response).to have_http_status(:forbidden)
  end

  context "com o supervisor" do
    before { sign_in com_papel("supervisor", "SUPERVISOR") }

    it "o Excel obedece os filtros: só os chamados da categoria e do período escolhidos" do
      get ti_estatisticas_path(format: :xlsx), params: { inicio: "01/09/2026", fim: "30/09/2026", categoria_id: redes.id }

      textos = textos_da_planilha(response.body)
      expect(textos).to include("Relatórios da TI", "01/09/2026 a 30/09/2026", "REDE", "SEM INTERNET")
      expect(textos).not_to include("IMPRESSORA PARADA", "HARDWARE")
    end

    it "o botão Exportar envia o formulário de filtros (vale o que está preenchido, mesmo sem ter filtrado)" do
      get ti_estatisticas_path

      botao = Nokogiri::HTML(response.body).at_css("button[title='Exportar Excel']")
      expect(botao.to_h.slice("type", "form", "formaction", "formmethod", "data-turbo")).to eq("type" => "submit", "form" => "filtros_do_relatorio", "formaction" => "/ti/relatorios.xlsx",
                                                                                                "formmethod" => "get", "data-turbo" => "false")
      expect(Nokogiri::HTML(response.body).at_css("form#filtros_do_relatorio")["action"]).to eq("/ti/relatorios")
    end

    it "fica em Administração → Relatórios, e o endereço antigo leva para lá" do
      get "/ti/estatisticas?inicio=01/09/2026"
      expect(response).to redirect_to("/ti/relatorios?inicio=01/09/2026")

      get ti_estatisticas_path
      menu = Nokogiri::HTML(response.body).css("a[href='/ti/relatorios']").map { |link| link.text.squish }
      expect(menu).to include("Relatórios")
    end
  end
end
