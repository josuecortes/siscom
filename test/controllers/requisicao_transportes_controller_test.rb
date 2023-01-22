require 'test_helper'

class RequisicaoTransportesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @requisicao_transporte = requisicao_transportes(:one)
  end

  test "should get index" do
    get requisicao_transportes_url
    assert_response :success
  end

  test "should get new" do
    get new_requisicao_transporte_url
    assert_response :success
  end

  test "should create requisicao_transporte" do
    assert_difference('RequisicaoTransporte.count') do
      post requisicao_transportes_url, params: { requisicao_transporte: { data_hora_ida: @requisicao_transporte.data_hora_ida, data_hora_retorno: @requisicao_transporte.data_hora_retorno, unidade_id: @requisicao_transporte.unidade_id, documento_viagem: @requisicao_transporte.documento_viagem, motivo: @requisicao_transporte.motivo, status: @requisicao_transporte.status, tipo: @requisicao_transporte.tipo, user_id: @requisicao_transporte.user_id } }
    end

    assert_redirected_to requisicao_transporte_url(RequisicaoTransporte.last)
  end

  test "should show requisicao_transporte" do
    get requisicao_transporte_url(@requisicao_transporte)
    assert_response :success
  end

  test "should get edit" do
    get edit_requisicao_transporte_url(@requisicao_transporte)
    assert_response :success
  end

  test "should update requisicao_transporte" do
    patch requisicao_transporte_url(@requisicao_transporte), params: { requisicao_transporte: { data_hora_ida: @requisicao_transporte.data_hora_ida, data_hora_retorno: @requisicao_transporte.data_hora_retorno, unidade_id: @requisicao_transporte.unidade_id, documento_viagem: @requisicao_transporte.documento_viagem, motivo: @requisicao_transporte.motivo, status: @requisicao_transporte.status, tipo: @requisicao_transporte.tipo, user_id: @requisicao_transporte.user_id } }
    assert_redirected_to requisicao_transporte_url(@requisicao_transporte)
  end

  test "should destroy requisicao_transporte" do
    assert_difference('RequisicaoTransporte.count', -1) do
      delete requisicao_transporte_url(@requisicao_transporte)
    end

    assert_redirected_to requisicao_transportes_url
  end
end
