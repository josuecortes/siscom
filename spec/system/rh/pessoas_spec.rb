require "rails_helper"

RSpec.describe "RH: pessoas", :js do
  let(:operador) { create(:user, nome: "OPERADOR DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }

  before do
    Rh::Tabelas.garantir_padroes
    create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
    create(:rh_funcao, nome: "Técnico")
    sign_in operador
  end

  it "cadastra uma pessoa com máscaras, recebe a senha da conta, lota e encerra" do
    visit rh_pessoas_path
    click_on "Nova pessoa"
    fill_in "Nome completo *", with: "Ana Paula Lima"
    fill_in "E-mail *", with: "ana@seed.ap.gov.br"
    fill_in "Celular *", with: "96991234567"
    fill_in "CPF *", with: "11144477735"
    fill_in "Data de nascimento", with: "02031990"
    expect(page).to have_field("Celular *", with: "(96) 99123-4567")
    expect(page).to have_field("CPF *", with: "111.444.777-35")
    expect(page).to have_field("Data de nascimento", with: "02/03/1990")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-pessoa-painel.png") if ENV["SCREENSHOT_DIR"]
    click_on "Cadastrar pessoa"

    expect(page).to have_css("[role='dialog'] h2", text: "Conta de acesso criada")
    senha = find("[data-senha-temporaria]").text
    expect(User.find_by!(email: "ana@seed.ap.gov.br").valid_password?(senha)).to be(true)
    click_on "Concluir"

    expect(page).to have_css("h1", text: "ANA PAULA LIMA")
    expect(page).to have_content("02/03/1990")

    click_on "Nova lotação"
    select "NUINFO - NÚCLEO DE INFORMÁTICA", from: "Unidade *"
    select "TÉCNICO", from: "Função *"
    click_on "Salvar lotação"
    expect(page).to have_css("#avisos", text: "Lotação registrada com sucesso.")
    expect(page).to have_content("1 ativa(s) de 1 registrada(s)")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-ficha.png") if ENV["SCREENSHOT_DIR"]

    click_on "Encerrar lotação"
    within("#confirmacao") { click_on "Encerrar" }
    expect(page).to have_css("#avisos", text: "Lotação encerrada.")
    expect(page).to have_content("0 ativa(s) de 1 registrada(s)")
  end

  it "o usuário comum chega à própria ficha pelo menu" do
    pessoa = create(:rh_pessoa, nome: "Maria Oliveira", user: create(:user, nome: "MARIA OLIVEIRA"))
    Capybara.reset_sessions!
    sign_in pessoa.user

    visit root_path
    within("#menu-lateral") do
      find("summary", text: "RH").click
      expect(page).to have_no_link("Pessoas")
      click_on "Minha ficha"
    end

    expect(page).to have_css("h1", text: "Minha ficha")
    expect(page).to have_content("MARIA OLIVEIRA")
  end

  it "o administrador do RH troca a permissão de um usuário pelo painel" do
    admin = create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") }
    create(:user, nome: "MARIA OLIVEIRA")
    Capybara.reset_sessions!
    sign_in admin

    visit rh_acessos_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Gerenciar permissões" }
    choose "Leitor"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-acessos.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar permissão"

    expect(page).to have_css("#avisos", text: "Permissão de MARIA OLIVEIRA atualizada.")
    within("tr", text: "MARIA OLIVEIRA") { expect(page).to have_content("Leitor") }
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "lista e ficha não criam rolagem horizontal" do
      pessoa = create(:rh_pessoa, nome: "Maria Oliveira")
      create(:rh_lotacao, pessoa: pessoa)

      [ rh_pessoas_path, rh_pessoa_path(pessoa), rh_lotacoes_path ].each do |caminho|
        visit caminho
        expect(page).to have_css("main h1")
        expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      end
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-lotacoes-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
