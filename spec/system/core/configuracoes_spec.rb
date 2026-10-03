require "rails_helper"

RSpec.describe "Administração: configurações", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  before { sign_in superadmin }

  it "muda o nome e o ícone da marca e vê o resultado na hora" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Administração").click
      click_on "Configurações"
    end
    expect(page).to have_css("h1", text: "Configurações")

    fill_in "Nome da marca (computador) *", with: "Portal SEED"
    fill_in "Nome no cabeçalho (computador) *", with: "Portal da Educação"
    attach_file "Arquivo do ícone da marca", Rails.root.join("spec/fixtures/files/avatar.png")
    click_on "Salvar configurações"

    expect(page).to have_css("#avisos", text: "Configurações salvas.")
    expect(page).to have_css("#menu-lateral", text: "Portal SEED")
    expect(page).to have_css("header", text: "Portal da Educação")
    expect(page).to have_css("#menu-lateral a img")
    expect(page).to have_content("Remover a imagem atual")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/configuracoes.png") if ENV["SCREENSHOT_DIR"]
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      visit core_configuracoes_path

      expect(page).to have_css("h1", text: "Configurações")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/configuracoes-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
