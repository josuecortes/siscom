require "application_system_test_case"

class TransporteEscolar::TransportadoresTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_transportador = transporte_escolar_transportadores(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_transportadores_url
    assert_selector "h1", text: "Transporte Escolar/Transportadores"
  end

  test "creating a Transportador" do
    visit transporte_escolar_transportadores_url
    click_on "New Transporte Escolar/Transportador"

    fill_in "Bairro", with: @transporte_escolar_transportador.bairro
    fill_in "Cep", with: @transporte_escolar_transportador.cep
    fill_in "Cnpj", with: @transporte_escolar_transportador.cnpj
    fill_in "Cpf", with: @transporte_escolar_transportador.cpf
    fill_in "Logradouro", with: @transporte_escolar_transportador.logradouro
    fill_in "Municipio", with: @transporte_escolar_transportador.municipio_id
    fill_in "Nome", with: @transporte_escolar_transportador.nome
    fill_in "Numero", with: @transporte_escolar_transportador.numero
    fill_in "Razao social", with: @transporte_escolar_transportador.razao_social
    fill_in "Tipo", with: @transporte_escolar_transportador.tipo
    click_on "Create Transportador"

    assert_text "Transportador was successfully created"
    click_on "Back"
  end

  test "updating a Transportador" do
    visit transporte_escolar_transportadores_url
    click_on "Edit", match: :first

    fill_in "Bairro", with: @transporte_escolar_transportador.bairro
    fill_in "Cep", with: @transporte_escolar_transportador.cep
    fill_in "Cnpj", with: @transporte_escolar_transportador.cnpj
    fill_in "Cpf", with: @transporte_escolar_transportador.cpf
    fill_in "Logradouro", with: @transporte_escolar_transportador.logradouro
    fill_in "Municipio", with: @transporte_escolar_transportador.municipio_id
    fill_in "Nome", with: @transporte_escolar_transportador.nome
    fill_in "Numero", with: @transporte_escolar_transportador.numero
    fill_in "Razao social", with: @transporte_escolar_transportador.razao_social
    fill_in "Tipo", with: @transporte_escolar_transportador.tipo
    click_on "Update Transportador"

    assert_text "Transportador was successfully updated"
    click_on "Back"
  end

  test "destroying a Transportador" do
    visit transporte_escolar_transportadores_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Transportador was successfully destroyed"
  end
end
