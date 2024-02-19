require "application_system_test_case"

class TransporteEscolar::CondutoresTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_condutor = transporte_escolar_condutores(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_condutores_url
    assert_selector "h1", text: "Transporte Escolar/Condutores"
  end

  test "creating a Condutor" do
    visit transporte_escolar_condutores_url
    click_on "New Transporte Escolar/Condutor"

    fill_in "Bairro", with: @transporte_escolar_condutor.bairro
    fill_in "Cep", with: @transporte_escolar_condutor.cep
    fill_in "Cpf", with: @transporte_escolar_condutor.cpf
    fill_in "Logradouro", with: @transporte_escolar_condutor.logradouro
    fill_in "Municipio", with: @transporte_escolar_condutor.municipio_id
    fill_in "Nome", with: @transporte_escolar_condutor.nome
    fill_in "Numero", with: @transporte_escolar_condutor.numero
    fill_in "Permissao", with: @transporte_escolar_condutor.permissao
    fill_in "Tipo", with: @transporte_escolar_condutor.tipo
    fill_in "Vencimento", with: @transporte_escolar_condutor.vencimento
    click_on "Create Condutor"

    assert_text "Condutor was successfully created"
    click_on "Back"
  end

  test "updating a Condutor" do
    visit transporte_escolar_condutores_url
    click_on "Edit", match: :first

    fill_in "Bairro", with: @transporte_escolar_condutor.bairro
    fill_in "Cep", with: @transporte_escolar_condutor.cep
    fill_in "Cpf", with: @transporte_escolar_condutor.cpf
    fill_in "Logradouro", with: @transporte_escolar_condutor.logradouro
    fill_in "Municipio", with: @transporte_escolar_condutor.municipio_id
    fill_in "Nome", with: @transporte_escolar_condutor.nome
    fill_in "Numero", with: @transporte_escolar_condutor.numero
    fill_in "Permissao", with: @transporte_escolar_condutor.permissao
    fill_in "Tipo", with: @transporte_escolar_condutor.tipo
    fill_in "Vencimento", with: @transporte_escolar_condutor.vencimento
    click_on "Update Condutor"

    assert_text "Condutor was successfully updated"
    click_on "Back"
  end

  test "destroying a Condutor" do
    visit transporte_escolar_condutores_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Condutor was successfully destroyed"
  end
end
