require 'test_helper'

class PassageirosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @passageiro = passageiros(:one)
  end

  test "should get index" do
    get passageiros_url
    assert_response :success
  end

  test "should get new" do
    get new_passageiro_url
    assert_response :success
  end

  test "should create passageiro" do
    assert_difference('Passageiro.count') do
      post passageiros_url, params: { passageiro: { celular: @passageiro.celular, cpf: @passageiro.cpf, nome: @passageiro.nome, requisicao_transporte_id: @passageiro.requisicao_transporte_id, user_id: @passageiro.user_id } }
    end

    assert_redirected_to passageiro_url(Passageiro.last)
  end

  test "should show passageiro" do
    get passageiro_url(@passageiro)
    assert_response :success
  end

  test "should get edit" do
    get edit_passageiro_url(@passageiro)
    assert_response :success
  end

  test "should update passageiro" do
    patch passageiro_url(@passageiro), params: { passageiro: { celular: @passageiro.celular, cpf: @passageiro.cpf, nome: @passageiro.nome, requisicao_transporte_id: @passageiro.requisicao_transporte_id, user_id: @passageiro.user_id } }
    assert_redirected_to passageiro_url(@passageiro)
  end

  test "should destroy passageiro" do
    assert_difference('Passageiro.count', -1) do
      delete passageiro_url(@passageiro)
    end

    assert_redirected_to passageiros_url
  end
end
