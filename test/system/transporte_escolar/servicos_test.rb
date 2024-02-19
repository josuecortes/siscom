require "application_system_test_case"

class TransporteEscolar::ServicosTest < ApplicationSystemTestCase
  setup do
    @transporte_escolar_servico = transporte_escolar_servicos(:one)
  end

  test "visiting the index" do
    visit transporte_escolar_servicos_url
    assert_selector "h1", text: "Transporteescolar::servicos"
  end

  test "creating a Servico" do
    visit transporte_escolar_servicos_url
    click_on "New Transporteescolar::servico"

    fill_in "Ano mes", with: @transporte_escolar_servico.ano_mes
    fill_in "Contrato", with: @transporte_escolar_servico.contrato_id
    fill_in "Diarias", with: @transporte_escolar_servico.diarias
    fill_in "Numero", with: @transporte_escolar_servico.numero
    fill_in "Status", with: @transporte_escolar_servico.status
    click_on "Create Servico"

    assert_text "Servico was successfully created"
    click_on "Back"
  end

  test "updating a Servico" do
    visit transporte_escolar_servicos_url
    click_on "Edit", match: :first

    fill_in "Ano mes", with: @transporte_escolar_servico.ano_mes
    fill_in "Contrato", with: @transporte_escolar_servico.contrato_id
    fill_in "Diarias", with: @transporte_escolar_servico.diarias
    fill_in "Numero", with: @transporte_escolar_servico.numero
    fill_in "Status", with: @transporte_escolar_servico.status
    click_on "Update Servico"

    assert_text "Servico was successfully updated"
    click_on "Back"
  end

  test "destroying a Servico" do
    visit transporte_escolar_servicos_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Servico was successfully destroyed"
  end
end
