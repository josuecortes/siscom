require "rails_helper"

RSpec.describe "Administração: usuários", :js do
  let(:admin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  before do
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    create(:user, nome: "JOAO SANTOS", email: "joao@seed.ap.gov.br", status: false)
    sign_in admin
  end

  it "chega pelo menu e filtra ao digitar" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Administração").click
      click_on "Usuários"
    end
    expect(page).to have_css("h1", text: "Usuários")
    expect(page).to have_content("3 usuário(s) cadastrado(s) no sistema")
    print("usuarios-lista")

    fill_in "Buscar por nome ou e-mail", with: "maria"

    expect(page).to have_content("1 usuário(s) encontrado(s)")
    expect(page).to have_no_content("JOAO SANTOS")
    expect(page).to have_current_path(/q=maria/)
  end

  it "cadastra pelo painel, mostra a senha temporária e atualiza a lista" do
    visit core_usuarios_path
    click_on "Novo usuário"
    expect(page).to have_css("[role='dialog'] h2", text: "Cadastrar usuário")

    fill_in "Nome completo *", with: "Ana Paula"
    fill_in "E-mail *", with: "maria@seed.ap.gov.br"
    click_on "Salvar usuário"
    expect(page).to have_content("E-mail já está em uso")
    print("usuarios-painel-erro")

    fill_in "E-mail *", with: "ana@seed.ap.gov.br"
    click_on "Salvar usuário"

    expect(page).to have_css("[role='dialog'] h2", text: "Senha temporária")
    senha = find("[data-senha-temporaria]").text
    expect(User.find_by!(email: "ana@seed.ap.gov.br").valid_password?(senha)).to be(true)
    print("usuarios-senha-temporaria")

    click_on "Concluir"
    expect(page).to have_no_css("[role='dialog']")
    expect(page).to have_content("ANA PAULA")
  end

  it "edita pelo painel e mostra o aviso flutuante" do
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Editar usuário" }
    fill_in "Nome completo *", with: "Maria Oliveira Souza"
    click_on "Salvar usuário"

    expect(page).to have_no_css("[role='dialog']")
    expect(page).to have_css("#avisos", text: "Usuário atualizado com sucesso.")
    expect(page).to have_content("MARIA OLIVEIRA SOUZA")
  end

  it "fecha o painel com Esc e pelo botão Cancelar" do
    visit core_usuarios_path
    click_on "Novo usuário"
    expect(page).to have_css("[role='dialog']")
    find("body").send_keys(:escape)
    expect(page).to have_no_css("[role='dialog']")

    click_on "Novo usuário"
    click_on "Cancelar"
    expect(page).to have_no_css("[role='dialog']")
  end

  it "desativa com confirmação e pode cancelar" do
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Desativar usuário" }
    expect(page).to have_css("#confirmacao h2", text: "Desativar usuário")
    expect(page).to have_content("Confirme a desativação do usuário MARIA OLIVEIRA.")
    print("usuarios-confirmacao")

    within("#confirmacao") { click_on "Cancelar" }
    expect(page).to have_no_css("#confirmacao h2")
    expect(User.find_by!(email: "maria@seed.ap.gov.br")).to be_ativo

    within("tr", text: "MARIA OLIVEIRA") { click_on "Desativar usuário" }
    within("#confirmacao") { click_on "Desativar usuário" }

    expect(page).to have_css("#avisos", text: "Usuário desativado com sucesso.")
    within("tr", text: "MARIA OLIVEIRA") { expect(page).to have_content("Inativo") }
  end

  it "redefine a senha com confirmação e mostra a temporária" do
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Redefinir senha" }
    within("#confirmacao") { click_on "Redefinir senha" }

    expect(page).to have_css("[role='dialog'] h2", text: "Senha temporária")
    senha = find("[data-senha-temporaria]").text
    expect(User.find_by!(email: "maria@seed.ap.gov.br").valid_password?(senha)).to be(true)
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "abre o painel em altura inteira e não cria rolagem horizontal" do
      visit core_usuarios_path
      expect(page).to have_css("a[aria-label='Novo usuário']")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      print("usuarios-lista-celular")

      click_on "Novo usuário"
      expect(page).to have_css("[role='dialog'] h2", text: "Cadastrar usuário")
      painel = retangulo("[role='dialog']")
      expect(painel["altura"]).to be_within(2).of(page.evaluate_script("window.innerHeight"))
      expect(painel["x"] + painel["largura"]).to be_within(1).of(page.evaluate_script("window.innerWidth"))
      print("usuarios-painel-celular")
    end
  end
end
