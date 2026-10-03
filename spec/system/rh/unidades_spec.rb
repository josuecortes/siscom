require "rails_helper"

RSpec.describe "RH: unidades e referências", :js do
  let(:admin) { create(:user, nome: "ADMIN DO RH").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "admin") } }

  before do
    Rh::Tabelas.garantir_padroes
    create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO", tipo_unidade: create(:rh_tipo_unidade, nome: "Sede"))
    sign_in admin
  end

  it "navega pelo menu do RH, cria um cargo e uma unidade filha" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "RH").click
      find("summary", text: "Referências").click
      click_on "Cargos"
    end
    expect(page).to have_css("h1", text: "Cargos")

    click_on "Novo cargo"
    fill_in "Nome *", with: "Analista de sistemas"
    click_on "Salvar"
    expect(page).to have_css("#avisos", text: "Cargo criado com sucesso.")
    expect(page).to have_content("ANALISTA DE SISTEMAS")

    within("#menu-lateral") { click_on "Unidades" }
    click_on "Nova unidade"
    fill_in "Nome *", with: "Divisão de Redes"
    fill_in "Sigla (obrigatória, menos para escola)", with: "direde"
    select "SEDE", from: "Tipo de unidade *"
    escolher_no_autocomplete "Unidade superior", digitar: "nuin", opcao: "NUINFO - NÚCLEO DE INFORMÁTICA"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-unidade-painel.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar unidade"

    expect(page).to have_css("#avisos", text: "Unidade criada com sucesso.")
    within("tr", text: "DIVISÃO DE REDES") { expect(page).to have_content("NUINFO - NÚCLEO DE INFORMÁTICA") }
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-unidades.png") if ENV["SCREENSHOT_DIR"]
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      visit rh_unidades_path

      expect(page).to have_content("1 unidade(s) registrada(s)")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    end
  end
end
