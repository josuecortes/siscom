require "rails_helper"

RSpec.describe "Administração: fontes de referência", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  before { sign_in superadmin }

  it "cria uma fonte escolhendo a entidade e desativa com confirmação" do
    visit core_fontes_referencia_path
    expect(page).to have_content("6 fonte(s) registrada(s)")

    click_on "Nova fonte"
    expect(page).to have_css("[role='dialog'] h2", text: "Nova fonte")
    select "Administração > Usuários (usuarios)", from: "Entidade *"
    expect(page).to have_field("Nome *", with: "Administração > Usuários")
    expect(page).to have_checked_field("email")

    fill_in "Nome *", with: "Usuários por e-mail"
    select "email", from: "Campo visível *"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/fontes-painel.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar fonte"

    expect(page).to have_no_css("[role='dialog']")
    expect(page).to have_css("#avisos", text: "Fonte criada com sucesso.")
    expect(page).to have_content("7 fonte(s) registrada(s)")

    within("tr", text: "Usuários por e-mail") { click_on "Desativar fonte" }
    within("#confirmacao") { click_on "Desativar" }
    within("tr", text: "Usuários por e-mail") { expect(page).to have_content("Inativa") }
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/fontes-lista.png") if ENV["SCREENSHOT_DIR"]
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      visit core_fontes_referencia_path

      expect(page).to have_content("6 fonte(s) registrada(s)")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
  end
end
