require "rails_helper"

RSpec.describe "Transporte: motoristas e veículos", :js do
  let(:tecnico) { create(:user, nome: "TECNICO DO TRANSPORTE").tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "tecnico") } }

  before { sign_in tecnico }

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "cadastra um motorista pelo menu, com máscaras, e recebe a senha da conta" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Transporte").click
      click_on "Motoristas"
    end
    click_on "Novo motorista"
    fill_in "Nome completo *", with: "João da Silva"
    fill_in "E-mail da conta *", with: "joao@seed.ap.gov.br"
    fill_in "CPF *", with: "52998224725"
    expect(find_field("CPF *").value).to eq("529.982.247-25")
    fill_in "Data de nascimento *", with: "15011985"
    fill_in "Número da CNH *", with: "AB123456"
    select "D", from: "Categoria da CNH *"
    fill_in "Validade da CNH *", with: "31122030"
    print("transporte-motorista-painel")
    click_on "Cadastrar motorista"

    expect(page).to have_css("[role='dialog'] h2", text: "Conta de acesso criada")
    expect(find("[data-senha-temporaria]").text).to be_present
    click_on "Concluir"
    within("tr", text: "JOÃO DA SILVA") { expect(page).to have_content("529.982.247-25").and have_content("AB123456 · D").and have_content("31/12/2030") }
    print("transporte-motoristas")
  end

  it "cadastra um veículo e desativa com confirmação" do
    visit transporte_veiculos_path
    click_on "Novo veículo"
    fill_in "Placa *", with: "qlm1a23"
    fill_in "Marca *", with: "Toyota"
    fill_in "Modelo *", with: "Hilux"
    fill_in "Ano *", with: "2022"
    fill_in "Cor *", with: "Branca"
    fill_in "Capacidade de passageiros *", with: "4"
    select "Diesel", from: "Combustível *"
    fill_in "Consumo (km por litro) *", with: "9.5"
    fill_in "Odômetro atual (km) *", with: "12000"
    click_on "Cadastrar veículo"

    expect(page).to have_css("#avisos", text: "Veículo cadastrado com sucesso.")
    within("tr", text: "QLM1A23") { click_on "Desativar veículo" }
    within("#confirmacao") { click_on "Desativar" }
    within("tr", text: "QLM1A23") { expect(page).to have_content("Inativo") }
    print("transporte-veiculos")
  end

  it "no celular as listas e os painéis não criam rolagem horizontal" do
    create(:transporte_veiculo)
    usar_tela_de_celular
    visit transporte_veiculos_path
    expect(page).to have_content("1 veículo(s) registrado(s)")
    expect(sem_rolagem_horizontal?).to be(true)

    visit new_transporte_motorista_path
    expect(page).to have_css("[role='dialog'] h2", text: "Cadastrar motorista")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
