require "rails_helper"

RSpec.describe "TI: solicitações", :js do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }

  before do
    create(:ti_categoria, nome: "Rede")
    create(:ti_perfil_abertura, nome: "Geral", padrao: true)
    create(:ti_grupo_tecnico, nome: "Redes")
    sign_in admin
  end

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "cadastra a solicitação pelo menu e marca quem abre e quem atende" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "TI").click
      find("summary", text: "Administração").click
      click_on "Solicitações"
    end
    click_on "Nova solicitação"
    expect(page).to have_css("[role='dialog'] h2", text: "Nova solicitação")
    select "REDE", from: "Categoria *"
    fill_in "Nome *", with: "Sem internet"
    fill_in "Resumo *", with: "Computador sem acesso à internet"
    check "Permite abrir mais de um chamado ao mesmo tempo"
    print("ti-solicitacao-painel")
    click_on "Salvar solicitação"
    expect(page).to have_css("#avisos", text: "Solicitação criada com sucesso.")

    within("tr", text: "SEM INTERNET") { click_on "Perfis de abertura" }
    check "GERAL (padrão: todos os usuários)"
    click_on "Salvar"
    expect(page).to have_css("#avisos", text: "Perfis de abertura de SEM INTERNET atualizados.")

    within("tr", text: "SEM INTERNET") { click_on "Grupos técnicos" }
    check "REDES"
    click_on "Salvar"
    expect(page).to have_css("#avisos", text: "Grupos técnicos de SEM INTERNET atualizados.")

    within("tr", text: "SEM INTERNET") do
      expect(page).to have_content("GERAL").and have_content("REDES").and have_content("vários chamados abertos")
    end
    print("ti-solicitacoes-lista")
  end

  it "no celular a lista e o painel não criam rolagem horizontal" do
    create(:ti_problema, nome: "Sem internet")
    usar_tela_de_celular
    visit ti_solicitacoes_path
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Nova solicitação"
    expect(page).to have_css("[role='dialog'] h2", text: "Nova solicitação")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
