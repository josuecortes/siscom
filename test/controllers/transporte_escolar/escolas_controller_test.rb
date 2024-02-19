require 'test_helper'

class TransporteEscolar::EscolasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_escola = transporte_escolar_escolas(:one)
  end

  test "should get index" do
    get transporte_escolar_escolas_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_escola_url
    assert_response :success
  end

  test "should create transporte_escolar_escola" do
    assert_difference('TransporteEscolar::Escola.count') do
      post transporte_escolar_escolas_url, params: { transporte_escolar_escola: { bairro: @transporte_escolar_escola.bairro, cep: @transporte_escolar_escola.cep, codigo: @transporte_escolar_escola.codigo, logradouro: @transporte_escolar_escola.logradouro, municipio_id: @transporte_escolar_escola.municipio_id, nome: @transporte_escolar_escola.nome, numero: @transporte_escolar_escola.numero } }
    end

    assert_redirected_to transporte_escolar_escola_url(TransporteEscolar::Escola.last)
  end

  test "should show transporte_escolar_escola" do
    get transporte_escolar_escola_url(@transporte_escolar_escola)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_escola_url(@transporte_escolar_escola)
    assert_response :success
  end

  test "should update transporte_escolar_escola" do
    patch transporte_escolar_escola_url(@transporte_escolar_escola), params: { transporte_escolar_escola: { bairro: @transporte_escolar_escola.bairro, cep: @transporte_escolar_escola.cep, codigo: @transporte_escolar_escola.codigo, logradouro: @transporte_escolar_escola.logradouro, municipio_id: @transporte_escolar_escola.municipio_id, nome: @transporte_escolar_escola.nome, numero: @transporte_escolar_escola.numero } }
    assert_redirected_to transporte_escolar_escola_url(@transporte_escolar_escola)
  end

  test "should destroy transporte_escolar_escola" do
    assert_difference('TransporteEscolar::Escola.count', -1) do
      delete transporte_escolar_escola_url(@transporte_escolar_escola)
    end

    assert_redirected_to transporte_escolar_escolas_url
  end
end
