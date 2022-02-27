require "application_system_test_case"

class DestinosTest < ApplicationSystemTestCase
  setup do
    @destino = destinos(:one)
  end

  test "visiting the index" do
    visit destinos_url
    assert_selector "h1", text: "Destinos"
  end

  test "creating a Destino" do
    visit destinos_url
    click_on "New Destino"

    fill_in "Bairro", with: @destino.bairro
    fill_in "Cep", with: @destino.cep
    fill_in "Cidade", with: @destino.cidade
    fill_in "Descricao", with: @destino.descricao
    fill_in "Logradouro", with: @destino.logradouro
    fill_in "Numero", with: @destino.numero
    fill_in "Requisicao transporte", with: @destino.requisicao_transporte_id
    fill_in "Tipo", with: @destino.tipo
    fill_in "User", with: @destino.user_id
    click_on "Create Destino"

    assert_text "Destino was successfully created"
    click_on "Back"
  end

  test "updating a Destino" do
    visit destinos_url
    click_on "Edit", match: :first

    fill_in "Bairro", with: @destino.bairro
    fill_in "Cep", with: @destino.cep
    fill_in "Cidade", with: @destino.cidade
    fill_in "Descricao", with: @destino.descricao
    fill_in "Logradouro", with: @destino.logradouro
    fill_in "Numero", with: @destino.numero
    fill_in "Requisicao transporte", with: @destino.requisicao_transporte_id
    fill_in "Tipo", with: @destino.tipo
    fill_in "User", with: @destino.user_id
    click_on "Update Destino"

    assert_text "Destino was successfully updated"
    click_on "Back"
  end

  test "destroying a Destino" do
    visit destinos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Destino was successfully destroyed"
  end
end
