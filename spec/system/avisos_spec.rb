require "rails_helper"

RSpec.describe "Avisos flutuantes", :js do
  before { create(:user, email: "maria@seed.ap.gov.br", password: "Senha@Forte123") }

  def entrar
    visit new_user_session_path
    fill_in "E-mail", with: "maria@seed.ap.gov.br"
    fill_in "Senha", with: "Senha@Forte123"
    click_on "Entrar"
  end

  it "mostra o aviso no canto superior direito, sem empurrar a página" do
    entrar

    expect(page).to have_css("#avisos [role='status']", text: "Login efetuado com sucesso")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/aviso.png") if ENV["SCREENSHOT_DIR"]

    aviso = retangulo("#avisos [role='status']")
    expect(largura_da_tela - (aviso["x"] + aviso["largura"])).to be_between(0, 40)
    expect(aviso["y"]).to be_between(64, 100)
  end

  it "o título da página fica colado na barra do topo" do
    entrar
    expect(page).to have_css("main section h1", text: "Início")

    expect(retangulo("main section")["y"]).to be_within(1).of(retangulo("header")["altura"])
  end

  it "fecha no X" do
    entrar

    click_on "Fechar aviso"

    expect(page).to have_no_css("#avisos [role='status']")
  end
end
