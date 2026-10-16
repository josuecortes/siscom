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

    # De volta à lista: lotar fica na linha da pessoa, e a ficha abre no painel, só para leitura.
    expect(page).to have_css("h1", text: "Pessoas")
    within("tr", text: "ANA PAULA LIMA") { click_on "Nova lotação" }
    escolher_no_autocomplete "Unidade *", digitar: "informát", opcao: "NUINFO - NÚCLEO DE INFORMÁTICA"
    escolher_no_autocomplete "Função *", digitar: "téc", opcao: "TÉCNICO"
    click_on "Salvar lotação"
    expect(page).to have_css("#avisos", text: "Lotação registrada com sucesso.")

    within("tr", text: "ANA PAULA LIMA") { click_on "Ver ficha" }
    within("[role='dialog']") do
      expect(page).to have_css("h2", text: "ANA PAULA LIMA")
      expect(page).to have_content("02/03/1990").and have_content("1 ativa(s) de 1 registrada(s)")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-ficha.png") if ENV["SCREENSHOT_DIR"]
      click_on "Fechar"
    end

    visit rh_lotacoes_path
    within("tr", text: "ANA PAULA LIMA") { click_on "Encerrar lotação" }
    within("#confirmacao") { click_on "Encerrar" }
    expect(page).to have_css("#avisos", text: "Lotação encerrada.")
    expect(page).to have_content("0 lotação(ões) registrada(s)")
  end

  it "o usuário comum chega à própria ficha pelo menu" do
    pessoa = create(:rh_pessoa, nome: "Maria Oliveira", user: create(:user, nome: "MARIA OLIVEIRA"))
    Capybara.reset_sessions!
    sign_in pessoa.user

    visit root_path
    within("#menu-lateral") do
      expect(page).to have_no_css("summary", text: "RH")
      find("summary", text: "Minha área").click
      click_on "Minha ficha"
    end

    expect(page).to have_css("h1", text: "Minha ficha")
    expect(page).to have_content("MARIA OLIVEIRA")
  end

  it "abre Nova lotação pela lista e procura pessoa, unidade e função digitando" do
    create(:rh_pessoa, nome: "Maria Oliveira", email: "maria@seed.ap.gov.br")
    create(:rh_funcao, nome: "Assessor")

    visit rh_lotacoes_path
    click_on "Nova lotação"
    expect(page).to have_css("[role='dialog'] h2", text: "Conceder lotação")

    fill_in "Função *", with: "xyz"
    within("#lotacao_funcao_lista") do
      expect(page).to have_content('Nada encontrado para "xyz". Lista completa:')
      expect(all("[role='option']").map(&:text)).to eq(%w[ASSESSOR TÉCNICO])
    end
    escolher_no_autocomplete "Pessoa *", digitar: "mar", opcao: "MARIA OLIVEIRA"
    escolher_no_autocomplete "Unidade *", digitar: "nui", opcao: "NUINFO - NÚCLEO DE INFORMÁTICA"
    escolher_no_autocomplete "Função *", digitar: "téc", opcao: "TÉCNICO"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-nova-lotacao.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar lotação"

    expect(page).to have_css("#avisos", text: "Lotação registrada com sucesso.")
    within("tr", text: "MARIA OLIVEIRA") { expect(page).to have_content("NUINFO - NÚCLEO DE INFORMÁTICA") }
  end

  it "mostra as lotações ativas da pessoa escolhida na Nova lotação" do
    maria = create(:rh_pessoa, nome: "Maria Oliveira")
    create(:rh_pessoa, nome: "Marcos Souza")
    create(:rh_lotacao, pessoa: maria, unidade: Rh::Unidade.find_by!(sigla: "NUINFO"), funcao: Rh::Funcao.find_by!(nome: "TÉCNICO"))

    visit rh_lotacoes_path
    click_on "Nova lotação"
    expect(page).to have_no_content("Lotações ativas da pessoa")

    escolher_no_autocomplete "Pessoa *", digitar: "mar", opcao: "MARIA OLIVEIRA"
    within("#lotacoes_ativas") do
      expect(page).to have_content("Lotações ativas da pessoa")
      expect(page).to have_content("NÚCLEO DE INFORMÁTICA - TÉCNICO")
    end

    escolher_no_autocomplete "Pessoa *", digitar: "marc", opcao: "MARCOS SOUZA"
    expect(page).to have_no_content("Lotações ativas da pessoa")
  end

  it "avisa quando o texto foi digitado mas nada foi escolhido na lista" do
    create(:rh_pessoa, nome: "Maria Oliveira")

    visit rh_lotacoes_path
    click_on "Nova lotação"
    escolher_no_autocomplete "Pessoa *", digitar: "mar", opcao: "MARIA OLIVEIRA"
    fill_in "Unidade *", with: "nuinfo"
    escolher_no_autocomplete "Função *", digitar: "téc", opcao: "TÉCNICO"
    click_on "Salvar lotação"

    expect(page).to have_content("Unidade deve ser escolhida na lista")
    expect(page).to have_field("Pessoa *", with: "MARIA OLIVEIRA")
  end

  it "o administrador do RH troca a permissão de um usuário pelo painel" do
    admin = create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") }
    create(:user, nome: "MARIA OLIVEIRA")
    Capybara.reset_sessions!
    sign_in admin

    visit rh_permissoes_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Gerenciar permissões" }
    expect(find_field("Usuário", readonly: true).value).to start_with("MARIA OLIVEIRA (")
    within("[role='dialog']") { select "Leitor", from: "Permissão no RH" }
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
