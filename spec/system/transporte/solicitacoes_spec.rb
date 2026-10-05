require "rails_helper"

RSpec.describe "Transporte: solicitar transporte", :js do
  include ActiveSupport::Testing::TimeHelpers

  let(:maria) { create(:user, nome: "MARIA OLIVEIRA").tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: "solicitante") } }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:lugar) do
    { "display_name" => "Avenida FAB, Central, Macapá", "lat" => "0.034934", "lon" => "-51.069395",
      "address" => { "road" => "Avenida FAB", "suburb" => "Central", "city" => "Macapá", "state" => "Amapá", "postcode" => "68900-073" } }
  end
  # PNG transparente de 1 x 1, no lugar das imagens do mapa.
  let(:png) { Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=") }

  before do
    Rh::Tabelas.garantir_padroes
    stub_request(:get, %r{tile\.openstreetmap\.org}).to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: png)
    stub_request(:get, %r{nominatim\.openstreetmap\.org/search}).to_return(status: 200, headers: json, body: [ lugar ].to_json)
    stub_request(:get, %r{nominatim\.openstreetmap\.org/reverse}).to_return(status: 200, headers: json, body: lugar.to_json)
    stub_request(:get, "https://viacep.com.br/ws/68900073/json/")
      .to_return(status: 200, headers: json, body: { logradouro: "Avenida FAB", bairro: "Central", localidade: "Macapá", uf: "AP" }.to_json)
    sign_in maria
  end

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  def saida = (Time.current + 60.hours).strftime("%d%m%Y%H%M")

  it "abre pelo menu: CEP preenche o endereço, o mapa marca o ponto e a solicitação aparece na lista" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "Minha área").click
      click_on "Solicitações de transporte"
    end
    click_on "Nova solicitação"
    expect(page).to have_css("[role='dialog'] h2", text: "Solicitar transporte")
    expect(page).to have_no_field("Retorno (data e hora) *")
    expect(page).to have_css(".leaflet-container")

    fill_in "Saída (data e hora) *", with: saida
    fill_in "Motivo da solicitação *", with: "Reunião na SEAD"
    select "Esperar no local", from: "O motorista deve *"
    fill_in "Quanto tempo vai esperar (horas) *", with: "2"
    fill_in "CPF *", with: "52998224725"
    fill_in "Nome do passageiro *", with: "Maria Oliveira"
    fill_in "Nome do destino *", with: "SEAD"
    fill_in "CEP", with: "68900073"
    expect(page).to have_field("Rua, avenida… *", with: "Avenida FAB")
    fill_in "Número *", with: "96"
    find_field("Bairro *").click # sair do campo Número dispara a busca no mapa
    expect(page).to have_content("Ponto marcado no mapa.")
    expect(find("input[name$='[latitude]']", visible: :all).value).to eq("0.034934")
    print("transporte-nova-solicitacao")
    click_on "Enviar solicitação"

    expect(page).to have_css("#avisos", text: /Solicitação TR-\d{6} aberta com sucesso\./)
    solicitacao = Transporte::Solicitacao.sole
    expect(solicitacao.destinos.sole).to have_attributes(logradouro: "Avenida FAB", numero: "96", latitude: 0.034934)
    within("tr", text: solicitacao.codigo) { click_on "Visualizar solicitação" }
    expect(page).to have_content("Normal · Esperar no local").and have_content("Avenida FAB, 96 - Central, Macapá/AP")
    print("transporte-solicitacao")
  end

  it "clicar no mapa preenche o endereço; viagem pede retorno e documento; dá para acrescentar passageiros" do
    visit new_transporte_solicitacao_path
    expect(page).to have_css(".leaflet-container")

    find(".leaflet-container").click
    expect(page).to have_content("Endereço preenchido pelo mapa.")
    expect(page).to have_field("Cidade *", with: "Macapá")
    expect(page).to have_field("UF *", with: "AP")

    select "Viagem", from: "Tipo *"
    expect(page).to have_field("Retorno (data e hora) *")
    expect(page).to have_field("Documento da viagem *")

    click_on "Adicionar passageiro"
    expect(page).to have_field("Nome do passageiro *", count: 2)
    all("button[aria-label='Remover passageiro']").last.click
    expect(page).to have_field("Nome do passageiro *", count: 1)
  end

  it "no celular a lista e o painel não criam rolagem horizontal" do
    usar_tela_de_celular
    visit transporte_solicitacoes_path
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Nova solicitação"
    expect(page).to have_css(".leaflet-container")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
