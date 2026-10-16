require "rails_helper"

RSpec.describe "TI: grupos técnicos por técnico", :js do
  let(:supervisor) { create(:user, nome: "SUPERVISOR DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") } }

  before do
    create(:user, nome: "JOÃO CONCEIÇÃO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }
    %w[REDES SISTEMAS SUPORTE].each { |nome| create(:ti_grupo_tecnico, nome: nome) }
    sign_in supervisor
  end

  it "busca o técnico, marca vários grupos no painel e vê embaixo onde ele está" do
    visit ti_grupos_tecnicos_path
    click_on "Técnicos"
    fill_in "Buscar técnico por nome ou e-mail", with: "joao"
    within("tr", text: "JOÃO CONCEIÇÃO") { click_on "Gerenciar grupos de JOÃO CONCEIÇÃO" }

    within("#adicionar_grupos") do
      check "REDES"
      check "SUPORTE"
      expect(page).to have_content("2 marcados")
      click_on "Adicionar aos marcados"
    end

    expect(page).to have_content("JOÃO CONCEIÇÃO entrou em 2 grupo(s).")
    within("#grupos_do_tecnico") { click_on "Tirar de SUPORTE" }
    expect(page).to have_css("#grupos_do_tecnico li", count: 1, text: "REDES")
    click_on "Concluir"
    expect(page).to have_css("tr", text: "JOÃO CONCEIÇÃO").and have_content("1 grupo(s)")
  end

  it "no celular a aba Técnicos e o painel não criam rolagem horizontal" do
    usar_tela_de_celular
    visit ti_tecnicos_dos_grupos_path(q: "joao")
    expect(sem_rolagem_horizontal?).to be(true)
    click_on "Gerenciar grupos de JOÃO CONCEIÇÃO"
    expect(page).to have_button("Adicionar aos marcados")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
