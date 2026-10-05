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
      expect(response.body).to include("Solicitar transporte", "48 a 100 horas de antecedência", "Esperar no local", "Buscar depois", "Só deixar", "Adicionar passageiro", "Adicionar destino")
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
      expect(html.css("nav[aria-label='Etapas das solicitações'] a").map { |aba| aba.text.squish }).to eq([ "Solicitadas 1", "Aprovadas 0", "Em serviço 0", "Concluídas 0", "Canceladas 0" ])
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

      get transporte_solicitacao_path(solicitacao)
      expect(response.body).to include("Solicitação #{solicitacao.codigo}", "Normal · Buscar depois", "MARIA OLIVEIRA", "529.982.247-25",
                                       "Avenida FAB, 96 - Central, Macapá/AP", "Abrir no mapa", "3 hora(s)")

      sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "solicitante") }
      get transporte_solicitacao_path(solicitacao)
      expect(response).to have_http_status(:not_found)
    end
  end
end
