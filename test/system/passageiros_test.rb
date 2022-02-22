require "application_system_test_case"

class PassageirosTest < ApplicationSystemTestCase
  setup do
    @passageiro = passageiros(:one)
  end

  test "visiting the index" do
    visit passageiros_url
    assert_selector "h1", text: "Passageiros"
  end

  test "creating a Passageiro" do
    visit passageiros_url
    click_on "New Passageiro"

    fill_in "Celular", with: @passageiro.celular
    fill_in "Cpf", with: @passageiro.cpf
    fill_in "Nome", with: @passageiro.nome
    fill_in "Requisicao transporte", with: @passageiro.requisicao_transporte_id
    fill_in "User", with: @passageiro.user_id
    click_on "Create Passageiro"

    assert_text "Passageiro was successfully created"
    click_on "Back"
  end

  test "updating a Passageiro" do
    visit passageiros_url
    click_on "Edit", match: :first

    fill_in "Celular", with: @passageiro.celular
    fill_in "Cpf", with: @passageiro.cpf
    fill_in "Nome", with: @passageiro.nome
    fill_in "Requisicao transporte", with: @passageiro.requisicao_transporte_id
    fill_in "User", with: @passageiro.user_id
    click_on "Update Passageiro"

    assert_text "Passageiro was successfully updated"
    click_on "Back"
  end

  test "destroying a Passageiro" do
    visit passageiros_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Passageiro was successfully destroyed"
  end
end
