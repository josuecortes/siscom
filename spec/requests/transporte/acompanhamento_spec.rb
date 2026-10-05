require "rails_helper"

RSpec.describe "Transporte: painel de acompanhamento" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }

  def solicitacao(**atributos)
    Transporte::Solicitacao.create!({ tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Reunião", saida_em: 1.hour.from_now, solicitante: maria,
                                      solicitante_nome: maria.nome, solicitante_email: maria.email }.merge(atributos))
  end

  it "fica desligado enquanto não há senha na Configuração" do
    get transporte_acompanhamento_path

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("O painel de acompanhamento está desligado")
  end

  context "com a senha definida" do
    before { Transporte::Configuracao.atual.update!(senha_do_painel: "patio2026") }

    it "pede a senha, sem login, e recusa a errada" do
      get transporte_acompanhamento_path
      expect(response.body).to include("Informe a senha de acesso para visualizar o painel.", "Entrar no acompanhamento")
      expect(response.body).not_to include("Saídas aprovadas")

      post transporte_acompanhamento_path, params: { senha: "errada" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Senha de acesso inválida.")
    end

    it "com a senha certa mostra o quadro por etapa, com a cor de cada urgência, o relógio e a contagem" do
      solicitacao(status: "solicitada")
      atrasada = solicitacao(saida_em: 20.minutes.ago)
      solicitacao(saida_em: 5.days.from_now)
      solicitacao(status: "busca", modo: "buscar_depois", busca_horas: 1, busca_prevista_em: 20.minutes.from_now)
      em_servico = solicitacao(status: "em_servico")
      em_servico.servicos.create!(trecho: "ida", motorista: maria, motorista_nome: "JOAO MOTORISTA", veiculo: create(:transporte_veiculo, placa: "QLM1A23"),
                                  placa: "QLM1A23", odometro_inicial: 1, iniciado_em: Time.current)

      post transporte_acompanhamento_path, params: { senha: "patio2026" }
      follow_redirect!

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Acompanhamento em tempo real", "JOAO MOTORISTA · QLM1A23", "Devia ter saído há 20 min", atrasada.codigo, "Atualiza em")
      expect(html.css(".tv-coluna").map { |coluna| [ coluna.at_css("h2 span").text, coluna.css(".tv-cartao").pluck("data-nivel") ] })
        .to eq([ [ "Aguardando aprovação", %w[urgente] ], [ "Saídas aprovadas", %w[critico] ], [ "Em andamento", %w[normal] ], [ "Aguardando busca", %w[urgente] ] ])
      expect(html.css(".tv-resumo-item").map { |item| item.text.squish }).to eq([ "1 Atrasado", "2 Falta pouco", "0 Atenção", "1 No prazo" ])
      expect(html.at_css("[data-controller='painel-tv']")["data-painel-tv-intervalo-value"]).to eq("30")
    end

    it "sair do painel volta a pedir a senha" do
      post transporte_acompanhamento_path, params: { senha: "patio2026" }
      delete transporte_acompanhamento_path
      follow_redirect!

      expect(response.body).to include("Informe a senha de acesso")
    end
  end

  it "o administrador liga o painel pela Configuração; a senha não fica guardada em texto" do
    admin = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "admin") }
    sign_in admin

    patch transporte_configuracoes_path, params: { configuracao: { senha_do_painel: "123" } }
    expect(response).to have_http_status(:unprocessable_content)

    patch transporte_configuracoes_path, params: { configuracao: { senha_do_painel: "patio2026" } }
    configuracao = Transporte::Configuracao.atual
    expect(configuracao.senha_do_painel_confere?("patio2026")).to be(true)
    expect(configuracao.senha_do_painel_digest).not_to include("patio2026")
    expect(Core::RegistroAuditoria.recentes.first.dados).to eq("mudancas" => { "painel_de_acompanhamento" => "acesso alterado" })

    patch transporte_configuracoes_path, params: { configuracao: { senha_do_painel: "", espera_max_horas: 3 } }
    expect(Transporte::Configuracao.atual.senha_do_painel_confere?("patio2026")).to be(true)
  end
end
