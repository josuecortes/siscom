require "application_system_test_case"

class FuncoesTest < ApplicationSystemTestCase
  setup do
    @funcao = funcoes(:one)
  end

  test "visiting the index" do
    visit funcoes_url
    assert_selector "h1", text: "Funcoes"
  end

  test "creating a Funcao" do
    visit funcoes_url
    click_on "New Funcao"

    fill_in "Nome", with: @funcao.nome
    click_on "Create Funcao"

    assert_text "Funcao was successfully created"
    click_on "Back"
  end

  test "updating a Funcao" do
    visit funcoes_url
    click_on "Edit", match: :first

    fill_in "Nome", with: @funcao.nome
    click_on "Update Funcao"

    assert_text "Funcao was successfully updated"
    click_on "Back"
  end

  test "destroying a Funcao" do
    visit funcoes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Funcao was successfully destroyed"
  end
end
