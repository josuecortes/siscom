require 'test_helper'

class TransporteEscolar::CondutoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_condutor = transporte_escolar_condutores(:one)
  end

  test "should get index" do
    get transporte_escolar_condutores_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_condutor_url
    assert_response :success
  end

  test "should create transporte_escolar_condutor" do
    assert_difference('TransporteEscolar::Condutor.count') do
      post transporte_escolar_condutores_url, params: { transporte_escolar_condutor: { bairro: @transporte_escolar_condutor.bairro, cep: @transporte_escolar_condutor.cep, cpf: @transporte_escolar_condutor.cpf, logradouro: @transporte_escolar_condutor.logradouro, municipio_id: @transporte_escolar_condutor.municipio_id, nome: @transporte_escolar_condutor.nome, numero: @transporte_escolar_condutor.numero, permissao: @transporte_escolar_condutor.permissao, tipo: @transporte_escolar_condutor.tipo, vencimento: @transporte_escolar_condutor.vencimento } }
    end

    assert_redirected_to transporte_escolar_condutor_url(TransporteEscolar::Condutor.last)
  end

  test "should show transporte_escolar_condutor" do
    get transporte_escolar_condutor_url(@transporte_escolar_condutor)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_condutor_url(@transporte_escolar_condutor)
    assert_response :success
  end

  test "should update transporte_escolar_condutor" do
    patch transporte_escolar_condutor_url(@transporte_escolar_condutor), params: { transporte_escolar_condutor: { bairro: @transporte_escolar_condutor.bairro, cep: @transporte_escolar_condutor.cep, cpf: @transporte_escolar_condutor.cpf, logradouro: @transporte_escolar_condutor.logradouro, municipio_id: @transporte_escolar_condutor.municipio_id, nome: @transporte_escolar_condutor.nome, numero: @transporte_escolar_condutor.numero, permissao: @transporte_escolar_condutor.permissao, tipo: @transporte_escolar_condutor.tipo, vencimento: @transporte_escolar_condutor.vencimento } }
    assert_redirected_to transporte_escolar_condutor_url(@transporte_escolar_condutor)
  end

  test "should destroy transporte_escolar_condutor" do
    assert_difference('TransporteEscolar::Condutor.count', -1) do
      delete transporte_escolar_condutor_url(@transporte_escolar_condutor)
    end

    assert_redirected_to transporte_escolar_condutores_url
  end
end
