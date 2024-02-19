require 'test_helper'

class TransporteEscolar::ContratosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_contrato = transporte_escolar_contratos(:one)
  end

  test "should get index" do
    get transporte_escolar_contratos_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_contrato_url
    assert_response :success
  end

  test "should create transporte_escolar_contrato" do
    assert_difference('TransporteEscolar::Contrato.count') do
      post transporte_escolar_contratos_url, params: { transporte_escolar_contrato: { bigint: @transporte_escolar_contrato.bigint, codigo: @transporte_escolar_contrato.codigo, descricao: @transporte_escolar_contrato.descricao, escola_id: @transporte_escolar_contrato.escola_id, fim: @transporte_escolar_contrato.fim, inicio: @transporte_escolar_contrato.inicio, rota: @transporte_escolar_contrato.rota, transportador_id: @transporte_escolar_contrato.transportador_id, valor_diaria: @transporte_escolar_contrato.valor_diaria, valor_total: @transporte_escolar_contrato.valor_total } }
    end

    assert_redirected_to transporte_escolar_contrato_url(TransporteEscolar::Contrato.last)
  end

  test "should show transporte_escolar_contrato" do
    get transporte_escolar_contrato_url(@transporte_escolar_contrato)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_contrato_url(@transporte_escolar_contrato)
    assert_response :success
  end

  test "should update transporte_escolar_contrato" do
    patch transporte_escolar_contrato_url(@transporte_escolar_contrato), params: { transporte_escolar_contrato: { bigint: @transporte_escolar_contrato.bigint, codigo: @transporte_escolar_contrato.codigo, descricao: @transporte_escolar_contrato.descricao, escola_id: @transporte_escolar_contrato.escola_id, fim: @transporte_escolar_contrato.fim, inicio: @transporte_escolar_contrato.inicio, rota: @transporte_escolar_contrato.rota, transportador_id: @transporte_escolar_contrato.transportador_id, valor_diaria: @transporte_escolar_contrato.valor_diaria, valor_total: @transporte_escolar_contrato.valor_total } }
    assert_redirected_to transporte_escolar_contrato_url(@transporte_escolar_contrato)
  end

  test "should destroy transporte_escolar_contrato" do
    assert_difference('TransporteEscolar::Contrato.count', -1) do
      delete transporte_escolar_contrato_url(@transporte_escolar_contrato)
    end

    assert_redirected_to transporte_escolar_contratos_url
  end
end
