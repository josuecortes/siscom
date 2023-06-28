require "application_system_test_case"

class IncidentesTest < ApplicationSystemTestCase
  setup do
    @incidente = incidentes(:one)
  end

  test "visiting the index" do
    visit incidentes_url
    assert_selector "h1", text: "Incidentes"
  end

  test "creating a Incidente" do
    visit incidentes_url
    click_on "New Incidente"

    check "Ativo" if @incidente.ativo
    fill_in "Data hora fim", with: @incidente.data_hora_fim
    fill_in "Data hora inicio", with: @incidente.data_hora_inicio
    fill_in "Descricao", with: @incidente.descricao
    fill_in "Previsao de retorno", with: @incidente.previsao_de_retorno
    fill_in "Texto explicativo", with: @incidente.texto_explicativo
    click_on "Create Incidente"

    assert_text "Incidente was successfully created"
    click_on "Back"
  end

  test "updating a Incidente" do
    visit incidentes_url
    click_on "Edit", match: :first

    check "Ativo" if @incidente.ativo
    fill_in "Data hora fim", with: @incidente.data_hora_fim
    fill_in "Data hora inicio", with: @incidente.data_hora_inicio
    fill_in "Descricao", with: @incidente.descricao
    fill_in "Previsao de retorno", with: @incidente.previsao_de_retorno
    fill_in "Texto explicativo", with: @incidente.texto_explicativo
    click_on "Update Incidente"

    assert_text "Incidente was successfully updated"
    click_on "Back"
  end

  test "destroying a Incidente" do
    visit incidentes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Incidente was successfully destroyed"
  end
end
