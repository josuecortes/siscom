require "application_system_test_case"

class AcoesTest < ApplicationSystemTestCase
  setup do
    @acao = acoes(:one)
  end

  test "visiting the index" do
    visit acoes_url
    assert_selector "h1", text: "Acoes"
  end

  test "creating a Acao" do
    visit acoes_url
    click_on "New Acao"

    fill_in "Descricao", with: @acao.descricao
    fill_in "Fim", with: @acao.fim
    fill_in "Inicio", with: @acao.inicio
    check "Mostrar no site" if @acao.mostrar_no_site
    fill_in "Motivacao", with: @acao.motivacao
    fill_in "Nome", with: @acao.nome
    fill_in "Orcamento", with: @acao.orcamento
    fill_in "Status", with: @acao.status
    click_on "Create Acao"

    assert_text "Acao was successfully created"
    click_on "Back"
  end

  test "updating a Acao" do
    visit acoes_url
    click_on "Edit", match: :first

    fill_in "Descricao", with: @acao.descricao
    fill_in "Fim", with: @acao.fim
    fill_in "Inicio", with: @acao.inicio
    check "Mostrar no site" if @acao.mostrar_no_site
    fill_in "Motivacao", with: @acao.motivacao
    fill_in "Nome", with: @acao.nome
    fill_in "Orcamento", with: @acao.orcamento
    fill_in "Status", with: @acao.status
    click_on "Update Acao"

    assert_text "Acao was successfully updated"
    click_on "Back"
  end

  test "destroying a Acao" do
    visit acoes_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Acao was successfully destroyed"
  end
end
