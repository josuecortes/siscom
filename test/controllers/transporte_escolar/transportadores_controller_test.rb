require 'test_helper'

class TransporteEscolar::TransportadoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_transportador = transporte_escolar_transportadores(:one)
  end

  test "should get index" do
    get transporte_escolar_transportadores_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_transportador_url
    assert_response :success
  end

  test "should create transporte_escolar_transportador" do
    assert_difference('TransporteEscolar::Transportador.count') do
      post transporte_escolar_transportadores_url, params: { transporte_escolar_transportador: { bairro: @transporte_escolar_transportador.bairro, cep: @transporte_escolar_transportador.cep, cnpj: @transporte_escolar_transportador.cnpj, cpf: @transporte_escolar_transportador.cpf, logradouro: @transporte_escolar_transportador.logradouro, municipio_id: @transporte_escolar_transportador.municipio_id, nome: @transporte_escolar_transportador.nome, numero: @transporte_escolar_transportador.numero, razao_social: @transporte_escolar_transportador.razao_social, tipo: @transporte_escolar_transportador.tipo } }
    end

    assert_redirected_to transporte_escolar_transportador_url(TransporteEscolar::Transportador.last)
  end

  test "should show transporte_escolar_transportador" do
    get transporte_escolar_transportador_url(@transporte_escolar_transportador)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_transportador_url(@transporte_escolar_transportador)
    assert_response :success
  end

  test "should update transporte_escolar_transportador" do
    patch transporte_escolar_transportador_url(@transporte_escolar_transportador), params: { transporte_escolar_transportador: { bairro: @transporte_escolar_transportador.bairro, cep: @transporte_escolar_transportador.cep, cnpj: @transporte_escolar_transportador.cnpj, cpf: @transporte_escolar_transportador.cpf, logradouro: @transporte_escolar_transportador.logradouro, municipio_id: @transporte_escolar_transportador.municipio_id, nome: @transporte_escolar_transportador.nome, numero: @transporte_escolar_transportador.numero, razao_social: @transporte_escolar_transportador.razao_social, tipo: @transporte_escolar_transportador.tipo } }
    assert_redirected_to transporte_escolar_transportador_url(@transporte_escolar_transportador)
  end

  test "should destroy transporte_escolar_transportador" do
    assert_difference('TransporteEscolar::Transportador.count', -1) do
      delete transporte_escolar_transportador_url(@transporte_escolar_transportador)
    end

    assert_redirected_to transporte_escolar_transportadores_url
  end
end
