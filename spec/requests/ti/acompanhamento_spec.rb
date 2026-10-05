require "rails_helper"

RSpec.describe "TI: painel de acompanhamento" do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }

  it "fica desligado enquanto não há senha na Configuração da TI" do
    get ti_acompanhamento_path

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("O painel de acompanhamento está desligado", "TI → Administração → Configuração")
  end

  it "o administrador liga o painel pela Configuração; a senha não fica guardada em texto e o técnico não entra na tela" do
    sign_in admin
    get ti_configuracoes_path
    expect(response.body).to include("Painel de acompanhamento", "/ti/acompanhamento", "Está desligado")

    patch ti_configuracoes_path, params: { configuracao: { senha_do_painel: "123" } }
    expect(response).to have_http_status(:unprocessable_content)
    patch ti_configuracoes_path, params: { configuracao: { senha_do_painel: "suporte2026" } }

    configuracao = Ti::Configuracao.atual
    expect([ configuracao.senha_do_painel_confere?("suporte2026"), configuracao.senha_do_painel_digest.include?("suporte2026") ]).to eq([ true, false ])
    expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "configuracao.atualizada", dados: { "mudancas" => { "painel_de_acompanhamento" => "acesso alterado" } })

    sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }
    get ti_configuracoes_path
    expect(response).to have_http_status(:forbidden)
  end

  context "com a senha definida" do
    before { Ti::Configuracao.atual.update!(senha_do_painel: "suporte2026") }

    it "pede a senha, sem login, e recusa a errada; a do Transporte não vale aqui" do
      Transporte::Configuracao.atual.update!(senha_do_painel: "patio2026")

      get ti_acompanhamento_path
      expect(response.body).to include("Informe a senha de acesso para visualizar o painel.", "Entrar no acompanhamento")

      post ti_acompanhamento_path, params: { senha: "patio2026" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Senha de acesso inválida.")
    end

    it "com a senha certa mostra os chamados por etapa, com a cor de cada urgência, o relógio e a contagem" do
      solicitacao = create(:ti_problema, nome: "Sem internet")
      novo = { problema: solicitacao, solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA" }
      atrasado = Ti::Chamado.create!(novo.merge(aberto_em: 9.hours.ago))
      Ti::Chamado.create!(novo.merge(aberto_em: 5.minutes.ago, status: "em_atendimento", responsavel: create(:user, nome: "JOAO TECNICO")))

      post ti_acompanhamento_path, params: { senha: "suporte2026" }
      follow_redirect!

      html = Nokogiri::HTML(response.body)
      expect(response.body).to include("Acompanhamento em tempo real", "Sem responsável há 9 h", atrasado.codigo, "Em atendimento há", "Atualiza em")
      expect(html.css("#tv_atendimento .tv-cartao p").map { |linha| linha.text.squish }.values_at(2, 3, 4, 5))
        .to eq([ "MARIA OLIVEIRA", "NUINFO - NÚCLEO DE INFORMÁTICA", "SEM INTERNET", "Técnico: Joao Tecnico" ])
      expect(html.css(".tv-coluna").map { |coluna| [ coluna.at_css("h2 span").text, coluna.css(".tv-cartao").pluck("data-nivel") ] })
        .to eq([ [ "Aguardando atendimento", %w[critico] ], [ "Em triagem", [] ], [ "Em atendimento", %w[normal] ], [ "Parados", [] ] ])
      expect([ html.at_css(".tv-sobretitulo").text, html.at_css("turbo-cable-stream-source").present? ]).to eq([ "TI", true ])
    end

    it "sair do painel volta a pedir a senha" do
      post ti_acompanhamento_path, params: { senha: "suporte2026" }
      delete ti_acompanhamento_path
      follow_redirect!

      expect(response.body).to include("Informe a senha de acesso")
    end
  end
end
