require 'test_helper'

class AcoesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @acao = acoes(:one)
  end

  test "should get index" do
    get acoes_url
    assert_response :success
  end

  test "should get new" do
    get new_acao_url
    assert_response :success
  end

  test "should create acao" do
    assert_difference('Acao.count') do
      post acoes_url, params: { acao: { descricao: @acao.descricao, fim: @acao.fim, inicio: @acao.inicio, mostrar_no_site: @acao.mostrar_no_site, motivacao: @acao.motivacao, nome: @acao.nome, orcamento: @acao.orcamento, status: @acao.status } }
    end

    assert_redirected_to acao_url(Acao.last)
  end

  test "should show acao" do
    get acao_url(@acao)
    assert_response :success
  end

  test "should get edit" do
    get edit_acao_url(@acao)
    assert_response :success
  end

  test "should update acao" do
    patch acao_url(@acao), params: { acao: { descricao: @acao.descricao, fim: @acao.fim, inicio: @acao.inicio, mostrar_no_site: @acao.mostrar_no_site, motivacao: @acao.motivacao, nome: @acao.nome, orcamento: @acao.orcamento, status: @acao.status } }
    assert_redirected_to acao_url(@acao)
  end

  test "should destroy acao" do
    assert_difference('Acao.count', -1) do
      delete acao_url(@acao)
    end

    assert_redirected_to acoes_url
  end
end
