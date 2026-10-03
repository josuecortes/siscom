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

  it "preenche o endereço da escola pelo CEP e pede só o número" do
    create(:rh_tipo_unidade, nome: "Escola")
    stub_request(:get, "https://viacep.com.br/ws/68900073/json/")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { logradouro: "Avenida FAB", bairro: "Central", localidade: "Macapá", uf: "AP" }.to_json)

    visit rh_unidades_path
    click_on "Nova unidade"
    fill_in "Nome *", with: "Escola Estadual A"
    select "ESCOLA", from: "Tipo de unidade *"
    fill_in "CEP", with: "68900073"

    expect(page).to have_field("CEP", with: "68900-073")
    expect(page).to have_field("Rua, avenida…", with: "Avenida FAB")
    expect(page).to have_field("Bairro", with: "Central")
    expect(page).to have_field("Cidade", with: "Macapá")
    expect(page).to have_field("UF", with: "AP")
    expect(page).to have_content("Endereço preenchido pelo CEP. Informe o número.")
    expect(page.evaluate_script("document.activeElement.id")).to eq("unidade_dados_escola_numero")
    fill_in "Número", with: "1070"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/rh-endereco.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar unidade"

    expect(page).to have_css("#avisos", text: "Unidade criada com sucesso.")
    expect(Rh::Unidade.find_by!(nome: "ESCOLA ESTADUAL A").dados_escola.endereco_completo).to eq("Avenida FAB, 1070 - Central - Macapá/AP - CEP 68900-073")
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
