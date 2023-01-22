require "application_system_test_case"

class RequisicaoTransportesTest < ApplicationSystemTestCase
  setup do
    @requisicao_transporte = requisicao_transportes(:one)
  end

  test "visiting the index" do
    visit requisicao_transportes_url
    assert_selector "h1", text: "Requisicao Transportes"
  end

  test "creating a Requisicao transporte" do
    visit requisicao_transportes_url
    click_on "New Requisicao Transporte"

    fill_in "Data hora ida", with: @requisicao_transporte.data_hora_ida
    fill_in "Data hora retorno", with: @requisicao_transporte.data_hora_retorno
    fill_in "Unidade", with: @requisicao_transporte.unidade_id
    fill_in "Documento viagem", with: @requisicao_transporte.documento_viagem
    fill_in "Motivo", with: @requisicao_transporte.motivo
    fill_in "Status", with: @requisicao_transporte.status
    fill_in "Tipo", with: @requisicao_transporte.tipo
    fill_in "User", with: @requisicao_transporte.user_id
    click_on "Create Requisicao transporte"

    assert_text "Requisicao transporte was successfully created"
    click_on "Back"
  end

  test "updating a Requisicao transporte" do
    visit requisicao_transportes_url
    click_on "Edit", match: :first

    fill_in "Data hora ida", with: @requisicao_transporte.data_hora_ida
    fill_in "Data hora retorno", with: @requisicao_transporte.data_hora_retorno
    fill_in "Unidade", with: @requisicao_transporte.unidade_id
    fill_in "Documento viagem", with: @requisicao_transporte.documento_viagem
    fill_in "Motivo", with: @requisicao_transporte.motivo
    fill_in "Status", with: @requisicao_transporte.status
    fill_in "Tipo", with: @requisicao_transporte.tipo
    fill_in "User", with: @requisicao_transporte.user_id
    click_on "Update Requisicao transporte"

    assert_text "Requisicao transporte was successfully updated"
    click_on "Back"
  end

  test "destroying a Requisicao transporte" do
    visit requisicao_transportes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Requisicao transporte was successfully destroyed"
  end
end
