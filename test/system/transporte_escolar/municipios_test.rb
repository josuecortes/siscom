require "application_system_test_case"

class TransporteEscolar::MunicipiosTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_municipio = transporte_escolar_municipios(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_municipios_url
    assert_selector "h1", text: "Transporte Escolar/Municipios"
  end

  test "creating a Municipio" do
    visit transporte_escolar_municipios_url
    click_on "New Transporte Escolar/Municipio"

    fill_in "Nome", with: @transporte_escolar_municipio.nome
    fill_in "Tipo", with: @transporte_escolar_municipio.tipo
    click_on "Create Municipio"

    assert_text "Municipio was successfully created"
    click_on "Back"
  end

  test "updating a Municipio" do
    visit transporte_escolar_municipios_url
    click_on "Edit", match: :first

    fill_in "Nome", with: @transporte_escolar_municipio.nome
    fill_in "Tipo", with: @transporte_escolar_municipio.tipo
    click_on "Update Municipio"

    assert_text "Municipio was successfully updated"
    click_on "Back"
  end

  test "destroying a Municipio" do
    visit transporte_escolar_municipios_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Municipio was successfully destroyed"
  end
end
