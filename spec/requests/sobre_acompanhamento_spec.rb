require "rails_helper"

# Menu → Acompanhamento (TI e Transporte): a página que explica o painel de TV e tem o botão para abri-lo.
RSpec.describe "Página do acompanhamento" do
  def com_papel(modulo, papel, nome = "#{modulo.upcase} #{papel.upcase}") = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: modulo, papel: papel) }
  def pagina = Nokogiri::HTML(response.body)
  def menu = pagina.css("#menu-lateral a").map { |link| link.text.squish }

  it "na TI: administrador, supervisor, triador e técnico entram; o solicitante não" do
    acessos = %w[admin supervisor triagem tecnico].map do |papel|
      sign_in com_papel("ti", papel)
      get ti_sobre_acompanhamento_path
      response.status
    end
    sign_in create(:user)
    get ti_sobre_acompanhamento_path

    expect(acessos + [ response.status ]).to eq([ 200, 200, 200, 200, 403 ])
  end

  it "no Transporte: administrador e técnico entram; motorista e solicitante não" do
    acessos = %w[admin tecnico motorista solicitante].map do |papel|
      sign_in com_papel("transporte", papel)
      get transporte_sobre_acompanhamento_path
      response.status
    end

    expect(acessos).to eq([ 200, 200, 403, 403 ])
  end

  it "explica o painel, mostra quem tem a senha e o botão abre o painel numa aba nova" do
    Ti::Configuracao.atual.update!(senha_do_painel: "painel123")
    com_papel("ti", "admin", "ANA ADMINISTRADORA")
    sign_in com_papel("ti", "tecnico", "JOAO TECNICO")

    get ti_sobre_acompanhamento_path

    expect(menu).to include("Acompanhamento")
    expect(response.body).to include("/ti/acompanhamento", "senha própria", "Aguardando atendimento", "Painel ligado")
    expect(pagina.css("#administradores_do_painel li").map(&:text)).to eq([ "ANA ADMINISTRADORA" ])
    expect(pagina.at_css("a#abrir_o_painel").to_h.slice("href", "target")).to eq("href" => "/ti/acompanhamento", "target" => "_blank")
  end

  it "com o painel desligado, avisa onde ligar e o botão fica apagado" do
    sign_in com_papel("transporte", "tecnico")

    get transporte_sobre_acompanhamento_path

    expect(response.body).to include("Painel desligado", "Transporte → Administração → Configuração", "Aguardando aprovação")
    expect(pagina.at_css("#abrir_o_painel")).to have_attributes(name: "span")
  end
end
