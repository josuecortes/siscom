require "application_system_test_case"

class TransporteEscolar::EscolasTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_escola = transporte_escolar_escolas(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_escolas_url
    assert_selector "h1", text: "Transporte Escolar/Escolas"
  end

  test "creating a Escola" do
    visit transporte_escolar_escolas_url
    click_on "New Transporte Escolar/Escola"

    fill_in "Bairro", with: @transporte_escolar_escola.bairro
    fill_in "Cep", with: @transporte_escolar_escola.cep
    fill_in "Codigo", with: @transporte_escolar_escola.codigo
    fill_in "Logradouro", with: @transporte_escolar_escola.logradouro
    fill_in "Municipio", with: @transporte_escolar_escola.municipio_id
    fill_in "Nome", with: @transporte_escolar_escola.nome
    fill_in "Numero", with: @transporte_escolar_escola.numero
    click_on "Create Escola"

    assert_text "Escola was successfully created"
    click_on "Back"
  end

  test "updating a Escola" do
    visit transporte_escolar_escolas_url
    click_on "Edit", match: :first

    fill_in "Bairro", with: @transporte_escolar_escola.bairro
    fill_in "Cep", with: @transporte_escolar_escola.cep
    fill_in "Codigo", with: @transporte_escolar_escola.codigo
    fill_in "Logradouro", with: @transporte_escolar_escola.logradouro
    fill_in "Municipio", with: @transporte_escolar_escola.municipio_id
    fill_in "Nome", with: @transporte_escolar_escola.nome
    fill_in "Numero", with: @transporte_escolar_escola.numero
    click_on "Update Escola"

    assert_text "Escola was successfully updated"
    click_on "Back"
  end

  test "destroying a Escola" do
    visit transporte_escolar_escolas_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Escola was successfully destroyed"
  end
end
