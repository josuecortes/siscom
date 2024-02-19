require "application_system_test_case"

class TransporteEscolar::ContratosTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_contrato = transporte_escolar_contratos(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_contratos_url
    assert_selector "h1", text: "Transporte Escolar/Contratos"
  end

  test "creating a Contrato" do
    visit transporte_escolar_contratos_url
    click_on "New Transporte Escolar/Contrato"

    fill_in "Bigint", with: @transporte_escolar_contrato.bigint
    fill_in "Codigo", with: @transporte_escolar_contrato.codigo
    fill_in "Descricao", with: @transporte_escolar_contrato.descricao
    fill_in "Escola", with: @transporte_escolar_contrato.escola_id
    fill_in "Fim", with: @transporte_escolar_contrato.fim
    fill_in "Inicio", with: @transporte_escolar_contrato.inicio
    fill_in "Rota", with: @transporte_escolar_contrato.rota
    fill_in "Transportador", with: @transporte_escolar_contrato.transportador_id
    fill_in "Valor diaria", with: @transporte_escolar_contrato.valor_diaria
    fill_in "Valor total", with: @transporte_escolar_contrato.valor_total
    click_on "Create Contrato"

    assert_text "Contrato was successfully created"
    click_on "Back"
  end

  test "updating a Contrato" do
    visit transporte_escolar_contratos_url
    click_on "Edit", match: :first

    fill_in "Bigint", with: @transporte_escolar_contrato.bigint
    fill_in "Codigo", with: @transporte_escolar_contrato.codigo
    fill_in "Descricao", with: @transporte_escolar_contrato.descricao
    fill_in "Escola", with: @transporte_escolar_contrato.escola_id
    fill_in "Fim", with: @transporte_escolar_contrato.fim
    fill_in "Inicio", with: @transporte_escolar_contrato.inicio
    fill_in "Rota", with: @transporte_escolar_contrato.rota
    fill_in "Transportador", with: @transporte_escolar_contrato.transportador_id
    fill_in "Valor diaria", with: @transporte_escolar_contrato.valor_diaria
    fill_in "Valor total", with: @transporte_escolar_contrato.valor_total
    click_on "Update Contrato"

    assert_text "Contrato was successfully updated"
    click_on "Back"
  end

  test "destroying a Contrato" do
    visit transporte_escolar_contratos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Contrato was successfully destroyed"
  end
end
