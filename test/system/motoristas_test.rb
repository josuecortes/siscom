require "application_system_test_case"

class MotoristasTest < ApplicationSystemTestCase
  setup do
    @motorista = motoristas(:one)
  end

  test "visiting the index" do
    visit motoristas_url
    assert_selector "h1", text: "Motoristas"
  end

  test "creating a Motorista" do
    visit motoristas_url
    click_on "New Motorista"

    fill_in "Celular", with: @motorista.celular
    fill_in "Cnh", with: @motorista.cnh
    fill_in "Cpf", with: @motorista.cpf
    fill_in "Data nascimento", with: @motorista.data_nascimento
    fill_in "Nome", with: @motorista.nome
    fill_in "Validade cnh", with: @motorista.validade_cnh
    click_on "Create Motorista"

    assert_text "Motorista was successfully created"
    click_on "Back"
  end

  test "updating a Motorista" do
    visit motoristas_url
    click_on "Edit", match: :first

    fill_in "Celular", with: @motorista.celular
    fill_in "Cnh", with: @motorista.cnh
    fill_in "Cpf", with: @motorista.cpf
    fill_in "Data nascimento", with: @motorista.data_nascimento
    fill_in "Nome", with: @motorista.nome
    fill_in "Validade cnh", with: @motorista.validade_cnh
    click_on "Update Motorista"

    assert_text "Motorista was successfully updated"
    click_on "Back"
  end

  test "destroying a Motorista" do
    visit motoristas_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Motorista was successfully destroyed"
  end
end
