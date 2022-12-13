require "application_system_test_case"

class TipoProblemaTisTest < ApplicationSystemTestCase
  setup do
    @tipo_problema_ti = tipo_problema_tis(:one)
  end

  test "visiting the index" do
    visit tipo_problema_tis_url
    assert_selector "h1", text: "Tipo Problema Tis"
  end

  test "creating a Tipo problema ti" do
    visit tipo_problema_tis_url
    click_on "New Tipo Problema Ti"

    fill_in "Descricao", with: @tipo_problema_ti.descricao
    fill_in "Nome", with: @tipo_problema_ti.nome
    click_on "Create Tipo problema ti"

    assert_text "Tipo problema ti was successfully created"
    click_on "Back"
  end

  test "updating a Tipo problema ti" do
    visit tipo_problema_tis_url
    click_on "Edit", match: :first

    fill_in "Descricao", with: @tipo_problema_ti.descricao
    fill_in "Nome", with: @tipo_problema_ti.nome
    click_on "Update Tipo problema ti"

    assert_text "Tipo problema ti was successfully updated"
    click_on "Back"
  end

  test "destroying a Tipo problema ti" do
    visit tipo_problema_tis_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Tipo problema ti was successfully destroyed"
  end
end
