require "rails_helper"

RSpec.describe "Transporte: solicitações do solicitante" do
  include ActiveSupport::Testing::TimeHelpers

  let(:maria) { create(:user, nome: "MARIA OLIVEIRA").tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "solicitante") } }
  let(:dados) do
    { tipo: "normal", modo: "buscar_depois", busca_horas: "3", resumo: "Reunião na SEAD", saida_em: "08/10/2026 09:00",
      passageiros: { "0" => { cpf: "529.982.247-25", nome: "Maria Oliveira" } },
      destinos: { "0" => { nome: "SEAD", cep: "68900-073", logradouro: "Avenida FAB", numero: "96", bairro: "Central", cidade: "Macapá", uf: "AP",
                          latitude: "0.034934", longitude: "-51.069395" } } }
  end

  before do
    Rh::Tabelas.garantir_padroes
    travel_to Time.zone.local(2026, 10, 5, 8, 0)
  end

  it "quem não tem a permissão de solicitante não vê nem abre" do
    sign_in create(:user)

    respostas = [ -> { get transporte_solicitacoes_path }, -> { get new_transporte_solicitacao_path }, -> { post transporte_solicitacoes_path, params: { solicitacao: dados } } ]
                .map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
  end

  context "com solicitante" do
    before { sign_in maria }

    it "mostra o painel com a janela de antecedência, os tipos, os modos e o mapa do destino" do
      get new_transporte_solicitacao_path

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Nova solicitação de transporte", "48 a 100 horas de antecedência", "Esperar no local", "Buscar depois", "Só deixar", "Adicionar passageiro", "Adicionar destino")
      expect(html.at_css("[data-controller='cep mapa']")["data-mapa-tiles-value"]).to eq("/mapa/tiles/{z}/{x}/{y}")
      expect(html.css("template[data-lista-target='modelo']").size).to eq(2)
    end

    it "abre a solicitação e ela aparece na aba Solicitadas, com o contador" do
      post transporte_solicitacoes_path, params: { solicitacao: dados }

      solicitacao = Transporte::Solicitacao.sole
      expect(response).to redirect_to(transporte_solicitacoes_path)
      expect(solicitacao).to have_attributes(modo: "buscar_depois", busca_horas: 3, solicitante: maria)

      get transporte_solicitacoes_path
      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("1 solicitação(ões) em solicitadas", solicitacao.codigo, "Reunião na SEAD", "08/10/2026 09:00", "SEAD")
      expect(html.css("nav[aria-label='Etapas das solicitações'] a").map { |aba| aba.text.squish }).to eq([ "Solicitadas 1", "Aprovadas 0", "Reagendadas 0", "Em serviço 0", "Concluídas 0", "Canceladas 0" ])
    end

    it "com busca, as abas dão lugar à aba Resultado, com as solicitações de todas as etapas" do
      post transporte_solicitacoes_path, params: { solicitacao: dados }
      post transporte_solicitacoes_path, params: { solicitacao: dados.merge(resumo: "Reunião no MEC") }
      Transporte::Solicitacao.find_by!(resumo: "Reunião no MEC").update_columns(status: "cancelada", motivo_cancelamento: "Adiada")

      get transporte_solicitacoes_path, params: { q: "reuni" }

      html = Nokogiri::HTML(response.body)
      expect(html.css("nav[aria-label='Etapas das solicitações'] a")).to be_empty
      expect(html.at_css("nav[aria-label='Etapas das solicitações'] [aria-current='page']").text.squish).to eq("Resultado 2")
      expect(response.body).to include("2 solicitação(ões) encontrada(s), de todas as etapas", "Reunião na SEAD", "Reunião no MEC")
    end

    it "com erro, devolve o painel com o que foi digitado e as mensagens em cada lugar" do
      ruim = dados.deep_merge(saida_em: "06/10/2026 09:00", passageiros: { "0" => { cpf: "111.111.111-11" } }, destinos: { "0" => { numero: "" } })

      post transporte_solicitacoes_path, params: { solicitacao: ruim }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Saída está fora do prazo para pedir", "CPF não é válido", "Número não pode ficar em branco", 'value="Avenida FAB"', 'value="06/10/2026 09:00"')
      expect(Transporte::Solicitacao.count).to eq(0)
    end

    it "mostra a solicitação com passageiros, destinos e o link do mapa; a de outra pessoa não abre" do
      post transporte_solicitacoes_path, params: { solicitacao: dados }
      solicitacao = Transporte::Solicitacao.sole

      ver_no_painel transporte_solicitacao_path(solicitacao)
      expect(response.body).to include("Solicitação #{solicitacao.codigo}", "Normal · Buscar depois", "MARIA OLIVEIRA", "529.982.247-25",
                                       "Avenida FAB, 96 - Central, Macapá/AP", "Abrir no mapa", "3 hora(s)", "Histórico", "Solicitação aberta")
      expect(Nokogiri::HTML(response.body).at_css("turbo-frame#painel [role='dialog']")).to be_present

      # Aberta direto pela URL (link de notificação): vai para a lista, que abre o painel sozinha.
      get transporte_solicitacao_path(solicitacao)
      expect(response).to redirect_to("/transporte/solicitacoes?status=solicitada&painel=#{CGI.escape(transporte_solicitacao_path(solicitacao))}")
      follow_redirect!
      expect(Nokogiri::HTML(response.body).at_css("turbo-frame#painel")["src"]).to eq(transporte_solicitacao_path(solicitacao))

      sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "solicitante") }
      get transporte_solicitacao_path(solicitacao)
      expect(response).to have_http_status(:not_found)
    end

    it "enquanto está solicitada, a lista oferece editar e o painel volta com os dados e as regras da abertura" do
      post transporte_solicitacoes_path, params: { solicitacao: dados }
      solicitacao = Transporte::Solicitacao.sole

      get transporte_solicitacoes_path
      expect(response.body).to include("Editar solicitação", "Cancelar solicitação")
      get edit_transporte_solicitacao_path(solicitacao)
      expect(response.body).to include("Editar solicitação #{solicitacao.codigo}", "Salvar alterações", 'value="08/10/2026 09:00"', 'value="Avenida FAB"')

      patch transporte_solicitacao_path(solicitacao), params: { solicitacao: dados.merge(saida_em: "06/10/2026 09:00") }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Saída está fora do prazo para pedir", "Editar solicitação #{solicitacao.codigo}")
    end

    it "edita a saída, o modo e os passageiros; fica no histórico e a operação é avisada" do
      tecnico = create(:user, nome: "TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "tecnico") }
      post transporte_solicitacoes_path, params: { solicitacao: dados }
      solicitacao = Transporte::Solicitacao.sole
      novos = dados.merge(saida_em: "08/10/2026 14:00", modo: "so_deixar", resumo: "Reunião na SEAD (tarde)",
                          passageiros: { "0" => { cpf: "529.982.247-25", nome: "Maria Oliveira" }, "1" => { cpf: "111.444.777-35", nome: "Pedro Santos" } })

      patch transporte_solicitacao_path(solicitacao), params: { solicitacao: novos }

      expect(response).to redirect_to(transporte_solicitacoes_path)
      expect(solicitacao.reload).to have_attributes(saida_em: Time.zone.local(2026, 10, 8, 14, 0), modo: "so_deixar", busca_horas: nil, resumo: "Reunião na SEAD (tarde)", status: "solicitada")
      expect([ solicitacao.passageiros.map(&:nome), solicitacao.destinos.map(&:nome) ]).to eq([ [ "MARIA OLIVEIRA", "PEDRO SANTOS" ], [ "SEAD" ] ])
      expect(solicitacao.eventos.em_ordem.pluck(:tipo)).to eq(%w[aberta editada])
      expect(tecnico.notificacoes.last.titulo).to eq("Solicitação de transporte editada")
    end

    it "depois de aprovada não dá mais para editar" do
      post transporte_solicitacoes_path, params: { solicitacao: dados }
      solicitacao = Transporte::Solicitacao.sole
      solicitacao.update!(status: "aprovada")

      get transporte_solicitacoes_path, params: { status: "aprovada" }
      expect(response.body).not_to include("Editar solicitação")
      patch transporte_solicitacao_path(solicitacao), params: { solicitacao: dados.merge(resumo: "Outro motivo") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("só pode ser editada enquanto está solicitada")
      expect(solicitacao.reload.resumo).to eq("Reunião na SEAD")
    end
  end
end
