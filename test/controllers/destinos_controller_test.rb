require 'test_helper'

class DestinosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @destino = destinos(:one)
  end

  test "should get index" do
    get destinos_url
    assert_response :success
  end

  test "should get new" do
    get new_destino_url
    assert_response :success
  end

  test "should create destino" do
    assert_difference('Destino.count') do
      post destinos_url, params: { destino: { bairro: @destino.bairro, cep: @destino.cep, cidade: @destino.cidade, descricao: @destino.descricao, logradouro: @destino.logradouro, numero: @destino.numero, requisicao_transporte_id: @destino.requisicao_transporte_id, tipo: @destino.tipo, user_id: @destino.user_id } }
    end

    assert_redirected_to destino_url(Destino.last)
  end

  test "should show destino" do
    get destino_url(@destino)
    assert_response :success
  end

  test "should get edit" do
    get edit_destino_url(@destino)
    assert_response :success
  end

  test "should update destino" do
    patch destino_url(@destino), params: { destino: { bairro: @destino.bairro, cep: @destino.cep, cidade: @destino.cidade, descricao: @destino.descricao, logradouro: @destino.logradouro, numero: @destino.numero, requisicao_transporte_id: @destino.requisicao_transporte_id, tipo: @destino.tipo, user_id: @destino.user_id } }
    assert_redirected_to destino_url(@destino)
  end

  test "should destroy destino" do
    assert_difference('Destino.count', -1) do
      delete destino_url(@destino)
    end

    assert_redirected_to destinos_url
  end
end
