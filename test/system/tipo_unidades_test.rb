require "application_system_test_case"

class TipoUnidadesTest < ApplicationSystemTestCase
  setup do
    @tipo_unidade = tipo_unidades(:one)
  end

  test "visiting the index" do
    visit tipo_unidades_url
    assert_selector "h1", text: "Tipo Unidades"
  end

  test "creating a Tipo unidade" do
    visit tipo_unidades_url
    click_on "New Tipo Unidade"

    fill_in "Nome", with: @tipo_unidade.nome
    click_on "Create Tipo unidade"

    assert_text "Tipo unidade was successfully created"
    click_on "Back"
  end

  test "updating a Tipo unidade" do
    visit tipo_unidades_url
    click_on "Edit", match: :first

    fill_in "Nome", with: @tipo_unidade.nome
    click_on "Update Tipo unidade"

    assert_text "Tipo unidade was successfully updated"
    click_on "Back"
  end

  test "destroying a Tipo unidade" do
    visit tipo_unidades_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tipo unidade was successfully destroyed"
  end
end
