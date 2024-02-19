require 'test_helper'

class TransporteEscolar::ServicosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_servico = transporte_escolar_servicos(:one)
  end

  test "should get index" do
    get transporte_escolar_servicos_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_servico_url
    assert_response :success
  end

  test "should create transporte_escolar_servico" do
    assert_difference('TransporteEscolar::Servico.count') do
      post transporte_escolar_servicos_url, params: { transporte_escolar_servico: { ano_mes: @transporte_escolar_servico.ano_mes, contrato_id: @transporte_escolar_servico.contrato_id, diarias: @transporte_escolar_servico.diarias, numero: @transporte_escolar_servico.numero, status: @transporte_escolar_servico.status } }
    end

    assert_redirected_to transporte_escolar_servico_url(TransporteEscolar::Servico.last)
  end

  test "should show transporte_escolar_servico" do
    get transporte_escolar_servico_url(@transporte_escolar_servico)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_servico_url(@transporte_escolar_servico)
    assert_response :success
  end

  test "should update transporte_escolar_servico" do
    patch transporte_escolar_servico_url(@transporte_escolar_servico), params: { transporte_escolar_servico: { ano_mes: @transporte_escolar_servico.ano_mes, contrato_id: @transporte_escolar_servico.contrato_id, diarias: @transporte_escolar_servico.diarias, numero: @transporte_escolar_servico.numero, status: @transporte_escolar_servico.status } }
    assert_redirected_to transporte_escolar_servico_url(@transporte_escolar_servico)
  end

  test "should destroy transporte_escolar_servico" do
    assert_difference('TransporteEscolar::Servico.count', -1) do
      delete transporte_escolar_servico_url(@transporte_escolar_servico)
    end

    assert_redirected_to transporte_escolar_servicos_url
  end
end
