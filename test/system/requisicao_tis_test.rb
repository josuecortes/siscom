require "application_system_test_case"

class RequisicaoTisTest < ApplicationSystemTestCase
  setup do
    @requisicao_ti = requisicao_tis(:one)
  end

  test "visiting the index" do
    visit requisicao_tis_url
    assert_selector "h1", text: "Requisicao Tis"
  end

  test "creating a Requisicao ti" do
    visit requisicao_tis_url
    click_on "New Requisicao Ti"

    fill_in "Unidade", with: @requisicao_ti.unidade_id
    fill_in "Observacoes", with: @requisicao_ti.observacoes
    fill_in "Problema ti", with: @requisicao_ti.problema_ti_id
    fill_in "Solucao", with: @requisicao_ti.solucao
    fill_in "Status", with: @requisicao_ti.status
    fill_in "User", with: @requisicao_ti.user_id
    click_on "Create Requisicao ti"

    assert_text "Requisicao ti was successfully created"
    click_on "Back"
  end

  test "updating a Requisicao ti" do
    visit requisicao_tis_url
    click_on "Edit", match: :first

    fill_in "Unidade", with: @requisicao_ti.unidade_id
    fill_in "Observacoes", with: @requisicao_ti.observacoes
    fill_in "Problema ti", with: @requisicao_ti.problema_ti_id
    fill_in "Solucao", with: @requisicao_ti.solucao
    fill_in "Status", with: @requisicao_ti.status
    fill_in "User", with: @requisicao_ti.user_id
    click_on "Update Requisicao ti"

    assert_text "Requisicao ti was successfully updated"
    click_on "Back"
  end

  test "destroying a Requisicao ti" do
    visit requisicao_tis_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Requisicao ti was successfully destroyed"
  end
end
