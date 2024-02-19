require "application_system_test_case"

class TransporteEscolar::VeiculosTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_veiculo = transporte_escolar_veiculos(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_veiculos_url
    assert_selector "h1", text: "Transporte Escolar/Veiculos"
  end

  test "creating a Veiculo" do
    visit transporte_escolar_veiculos_url
    click_on "New Transporte Escolar/Veiculo"

    fill_in "Ano", with: @transporte_escolar_veiculo.ano
    fill_in "Capacidade carga", with: @transporte_escolar_veiculo.capacidade_carga
    fill_in "Capacidade pessoas", with: @transporte_escolar_veiculo.capacidade_pessoas
    fill_in "Condutor", with: @transporte_escolar_veiculo.condutor_id
    fill_in "Identificacao", with: @transporte_escolar_veiculo.identificacao
    fill_in "Marca", with: @transporte_escolar_veiculo.marca
    fill_in "Modelo", with: @transporte_escolar_veiculo.modelo
    fill_in "Tipo", with: @transporte_escolar_veiculo.tipo
    fill_in "Transportador", with: @transporte_escolar_veiculo.transportador_id
    click_on "Create Veiculo"

    assert_text "Veiculo was successfully created"
    click_on "Back"
  end

  test "updating a Veiculo" do
    visit transporte_escolar_veiculos_url
    click_on "Edit", match: :first

    fill_in "Ano", with: @transporte_escolar_veiculo.ano
    fill_in "Capacidade carga", with: @transporte_escolar_veiculo.capacidade_carga
    fill_in "Capacidade pessoas", with: @transporte_escolar_veiculo.capacidade_pessoas
    fill_in "Condutor", with: @transporte_escolar_veiculo.condutor_id
    fill_in "Identificacao", with: @transporte_escolar_veiculo.identificacao
    fill_in "Marca", with: @transporte_escolar_veiculo.marca
    fill_in "Modelo", with: @transporte_escolar_veiculo.modelo
    fill_in "Tipo", with: @transporte_escolar_veiculo.tipo
    fill_in "Transportador", with: @transporte_escolar_veiculo.transportador_id
    click_on "Update Veiculo"

    assert_text "Veiculo was successfully updated"
    click_on "Back"
  end

  test "destroying a Veiculo" do
    visit transporte_escolar_veiculos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Veiculo was successfully destroyed"
  end
end
