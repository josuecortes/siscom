require "rails_helper"

RSpec.describe "Shell administrativo", :js do
  let(:user) { create(:user, nome: "MARIA SILVA", email: "maria@seed.ap.gov.br") }

  before { sign_in user }

  it "alterna o tema e lembra a escolha" do
    visit root_path
    tema_inicial = page.evaluate_script("document.documentElement.dataset.theme")

    click_on "Alternar tema"

    tema_novo = tema_inicial == "dark" ? "light" : "dark"
    expect(page).to have_css("html[data-theme='#{tema_novo}']")

    visit root_path
    expect(page).to have_css("html[data-theme='#{tema_novo}']")
  end

  it "recolhe o menu lateral" do
    visit root_path
    expect(page).to have_css("#menu-lateral", text: /navegação/i)

    click_on "Recolher ou expandir menu lateral"

    expect(page).to have_css("html[data-menu='recolhido']")
    expect(page).to have_no_css("#menu-lateral", text: /navegação/i)
    page.save_screenshot(ENV["SCREENSHOT_PATH"]) if ENV["SCREENSHOT_PATH"]
  end

  it "abre o menu da conta e sai" do
    visit root_path

    click_on "Abrir menu da conta"
    click_on "Sair"

    expect(page).to have_current_path(new_user_session_path)
  end

  context "quando está no celular" do
    before { page.current_window.resize_to(390, 844) }

    it "esconde o menu lateral e abre a gaveta pelo botão do topo" do
      visit root_path
      expect(page).to have_no_css("#menu-lateral", visible: :visible)
      expect(page).to have_css("header", text: "SISCOM")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/mobile-topo.png") if ENV["SCREENSHOT_DIR"]

      click_on "Abrir menu"
      expect(page).to have_css("[data-menu-lateral-target='gaveta'] nav", text: "Início")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/mobile-gaveta.png") if ENV["SCREENSHOT_DIR"]

      within("[data-menu-lateral-target='gaveta'] > div") { click_on "Fechar menu" }
      expect(page).to have_no_css("[data-menu-lateral-target='gaveta']", visible: :visible)
    end

    it "não cria rolagem horizontal" do
      visit root_path

      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
  end
end
