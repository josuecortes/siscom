require 'test_helper'

class FuncoesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @funcao = funcoes(:one)
  end

  test "should get index" do
    get funcoes_url
    assert_response :success
  end

  test "should get new" do
    get new_funcao_url
    assert_response :success
  end

  test "should create funcao" do
    assert_difference('Funcao.count') do
      post funcoes_url, params: { funcao: { nome: @funcao.nome } }
    end

    assert_redirected_to funcao_url(Funcao.last)
  end

  test "should show funcao" do
    get funcao_url(@funcao)
    assert_response :success
  end

  test "should get edit" do
    get edit_funcao_url(@funcao)
    assert_response :success
  end

  test "should update funcao" do
    patch funcao_url(@funcao), params: { funcao: { nome: @funcao.nome } }
    assert_redirected_to funcao_url(@funcao)
  end

  test "should destroy funcao" do
    assert_difference('Funcao.count', -1) do
      delete funcao_url(@funcao)
    end

    assert_redirected_to funcoes_url
  end
end
