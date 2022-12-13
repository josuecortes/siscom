require "application_system_test_case"

class ProblemaTisTest < ApplicationSystemTestCase
  setup do
    @problema_ti = problema_tis(:one)
  end

  test "visiting the index" do
    visit problema_tis_url
    assert_selector "h1", text: "Problema Tis"
  end

  test "creating a Problema ti" do
    visit problema_tis_url
    click_on "New Problema Ti"

    fill_in "Descricao", with: @problema_ti.descricao
    fill_in "Nome", with: @problema_ti.nome
    fill_in "Tipo problema ti", with: @problema_ti.tipo_problema_ti_id
    click_on "Create Problema ti"

    assert_text "Problema ti was successfully created"
    click_on "Back"
  end

  test "updating a Problema ti" do
    visit problema_tis_url
    click_on "Edit", match: :first

    fill_in "Descricao", with: @problema_ti.descricao
    fill_in "Nome", with: @problema_ti.nome
    fill_in "Tipo problema ti", with: @problema_ti.tipo_problema_ti_id
    click_on "Update Problema ti"

    assert_text "Problema ti was successfully updated"
    click_on "Back"
  end

  test "destroying a Problema ti" do
    visit problema_tis_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Problema ti was successfully destroyed"
  end
end
