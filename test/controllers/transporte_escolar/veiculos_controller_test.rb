require 'test_helper'

class TransporteEscolar::VeiculosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_veiculo = transporte_escolar_veiculos(:one)
  end

  test "should get index" do
    get transporte_escolar_veiculos_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_veiculo_url
    assert_response :success
  end

  test "should create transporte_escolar_veiculo" do
    assert_difference('TransporteEscolar::Veiculo.count') do
      post transporte_escolar_veiculos_url, params: { transporte_escolar_veiculo: { ano: @transporte_escolar_veiculo.ano, capacidade_carga: @transporte_escolar_veiculo.capacidade_carga, capacidade_pessoas: @transporte_escolar_veiculo.capacidade_pessoas, condutor_id: @transporte_escolar_veiculo.condutor_id, identificacao: @transporte_escolar_veiculo.identificacao, marca: @transporte_escolar_veiculo.marca, modelo: @transporte_escolar_veiculo.modelo, tipo: @transporte_escolar_veiculo.tipo, transportador_id: @transporte_escolar_veiculo.transportador_id } }
    end

    assert_redirected_to transporte_escolar_veiculo_url(TransporteEscolar::Veiculo.last)
  end

  test "should show transporte_escolar_veiculo" do
    get transporte_escolar_veiculo_url(@transporte_escolar_veiculo)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_veiculo_url(@transporte_escolar_veiculo)
    assert_response :success
  end

  test "should update transporte_escolar_veiculo" do
    patch transporte_escolar_veiculo_url(@transporte_escolar_veiculo), params: { transporte_escolar_veiculo: { ano: @transporte_escolar_veiculo.ano, capacidade_carga: @transporte_escolar_veiculo.capacidade_carga, capacidade_pessoas: @transporte_escolar_veiculo.capacidade_pessoas, condutor_id: @transporte_escolar_veiculo.condutor_id, identificacao: @transporte_escolar_veiculo.identificacao, marca: @transporte_escolar_veiculo.marca, modelo: @transporte_escolar_veiculo.modelo, tipo: @transporte_escolar_veiculo.tipo, transportador_id: @transporte_escolar_veiculo.transportador_id } }
    assert_redirected_to transporte_escolar_veiculo_url(@transporte_escolar_veiculo)
  end

  test "should destroy transporte_escolar_veiculo" do
    assert_difference('TransporteEscolar::Veiculo.count', -1) do
      delete transporte_escolar_veiculo_url(@transporte_escolar_veiculo)
    end

    assert_redirected_to transporte_escolar_veiculos_url
  end
end
