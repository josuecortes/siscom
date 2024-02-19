require 'test_helper'

class TransporteEscolar::MunicipiosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @transporte_escolar_municipio = transporte_escolar_municipios(:one)
  end

  test "should get index" do
    get transporte_escolar_municipios_url
    assert_response :success
  end

  test "should get new" do
    get new_transporte_escolar_municipio_url
    assert_response :success
  end

  test "should create transporte_escolar_municipio" do
    assert_difference('TransporteEscolar::Municipio.count') do
      post transporte_escolar_municipios_url, params: { transporte_escolar_municipio: { nome: @transporte_escolar_municipio.nome, tipo: @transporte_escolar_municipio.tipo } }
    end

    assert_redirected_to transporte_escolar_municipio_url(TransporteEscolar::Municipio.last)
  end

  test "should show transporte_escolar_municipio" do
    get transporte_escolar_municipio_url(@transporte_escolar_municipio)
    assert_response :success
  end

  test "should get edit" do
    get edit_transporte_escolar_municipio_url(@transporte_escolar_municipio)
    assert_response :success
  end

  test "should update transporte_escolar_municipio" do
    patch transporte_escolar_municipio_url(@transporte_escolar_municipio), params: { transporte_escolar_municipio: { nome: @transporte_escolar_municipio.nome, tipo: @transporte_escolar_municipio.tipo } }
    assert_redirected_to transporte_escolar_municipio_url(@transporte_escolar_municipio)
  end

  test "should destroy transporte_escolar_municipio" do
    assert_difference('TransporteEscolar::Municipio.count', -1) do
      delete transporte_escolar_municipio_url(@transporte_escolar_municipio)
    end

    assert_redirected_to transporte_escolar_municipios_url
  end
end
