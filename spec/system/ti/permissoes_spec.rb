require "rails_helper"

RSpec.describe "TI: permissões", :js do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }

  before do
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    sign_in admin
  end

  it "chega pelo menu, marca duas permissões no painel e vê os selos na lista" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "TI").click
      find("summary", text: "Administração").click
      click_on "Permissões"
    end
    expect(page).to have_css("h1", text: "Permissões")

    within("tr", text: "MARIA OLIVEIRA") { click_on "Gerenciar permissões" }
    expect(page).to have_css("[role='dialog'] h2", text: "Gerenciar permissões de MARIA OLIVEIRA")
    check "Triador"
    check "Técnico"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/ti-permissoes.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar permissões"

    expect(page).to have_css("#avisos", text: "Permissões de MARIA OLIVEIRA atualizadas.")
    within("tr", text: "MARIA OLIVEIRA") { expect(page).to have_content("Triador").and have_content("Técnico") }
  end

  it "no celular o painel ocupa a tela, sem rolagem horizontal" do
    usar_tela_de_celular
    visit ti_permissoes_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Gerenciar permissões" }

    expect(page).to have_css("[role='dialog'] h2", text: "Gerenciar permissões de MARIA OLIVEIRA")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
