require 'test_helper'

class TipoUnidadesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tipo_unidade = tipo_unidades(:one)
  end

  test "should get index" do
    get tipo_unidades_url
    assert_response :success
  end

  test "should get new" do
    get new_tipo_unidade_url
    assert_response :success
  end

  test "should create tipo_unidade" do
    assert_difference('TipoUnidade.count') do
      post tipo_unidades_url, params: { tipo_unidade: { nome: @tipo_unidade.nome } }
    end

    assert_redirected_to tipo_unidade_url(TipoUnidade.last)
  end

  test "should show tipo_unidade" do
    get tipo_unidade_url(@tipo_unidade)
    assert_response :success
  end

  test "should get edit" do
    get edit_tipo_unidade_url(@tipo_unidade)
    assert_response :success
  end

  test "should update tipo_unidade" do
    patch tipo_unidade_url(@tipo_unidade), params: { tipo_unidade: { nome: @tipo_unidade.nome } }
    assert_redirected_to tipo_unidade_url(@tipo_unidade)
  end

  test "should destroy tipo_unidade" do
    assert_difference('TipoUnidade.count', -1) do
      delete tipo_unidade_url(@tipo_unidade)
    end

    assert_redirected_to tipo_unidades_url
  end
end
