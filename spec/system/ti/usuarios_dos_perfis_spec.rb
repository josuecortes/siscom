require "rails_helper"

RSpec.describe "TI: perfis de abertura por usuário", :js do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }

  before do
    create(:user, nome: "JOÃO CONCEIÇÃO", email: "joao@seed.ap.gov.br")
    %w[SOLICITANTE\ ESCOLAR SOLICITANTE\ DA\ SEDE DIRETOR].each { |nome| create(:ti_perfil_abertura, nome: nome) }
    sign_in admin
  end

  it "busca o usuário, marca vários perfis no painel e vê embaixo onde ele está" do
    visit ti_perfis_abertura_path
    click_on "Usuários"
    fill_in "Buscar usuário por nome ou e-mail", with: "joao"
    within("tr", text: "JOÃO CONCEIÇÃO") { click_on "Gerenciar perfis de JOÃO CONCEIÇÃO" }

    within("#adicionar_perfis") do
      check "SOLICITANTE ESCOLAR"
      check "DIRETOR"
      expect(page).to have_content("2 marcados")
      click_on "Adicionar aos marcados"
    end

    expect(page).to have_content("JOÃO CONCEIÇÃO entrou em 2 perfil(is).")
    expect(page).to have_css("#perfis_do_usuario li", count: 2)
    within("#perfis_do_usuario") { click_on "Remover de DIRETOR" }
    expect(page).to have_css("#perfis_do_usuario li", count: 1, text: "SOLICITANTE ESCOLAR")
    click_on "Concluir"
    expect(page).to have_css("tr", text: "JOÃO CONCEIÇÃO").and have_content("1 perfil(is)")
  end

  it "no celular a aba Usuários e o painel não criam rolagem horizontal" do
    usar_tela_de_celular
    visit ti_usuarios_dos_perfis_path(q: "joao")
    expect(sem_rolagem_horizontal?).to be(true)
    click_on "Gerenciar perfis de JOÃO CONCEIÇÃO"
    expect(page).to have_button("Adicionar aos marcados")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
