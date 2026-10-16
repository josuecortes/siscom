require "rails_helper"

RSpec.describe "Minha área: perfil", :js do
  let(:user) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "12345678901") }

  before { sign_in user }

  it "chega pelo menu da conta e troca a imagem" do
    visit root_path
    click_on "Abrir menu da conta"
    click_on "Perfil"
    expect(page).to have_css("h1", text: "Perfil")
    expect(page).to have_content("123.456.789-01")

    attach_file "Nova imagem do perfil", Rails.root.join("spec/fixtures/files/avatar.png")
    click_on "Trocar imagem"

    expect(page).to have_css("#avisos", text: "Imagem do perfil atualizada.")
    expect(page).to have_css("main img[alt='Avatar do usuário']")
    expect(page).to have_css("header img[alt='Avatar do usuário']")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/perfil.png") if ENV["SCREENSHOT_DIR"]
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      visit meu_perfil_path

      expect(page).to have_css("h1", text: "Perfil")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/perfil-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
