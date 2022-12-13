require 'test_helper'

class TipoProblemaTisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tipo_problema_ti = tipo_problema_tis(:one)
  end

  test "should get index" do
    get tipo_problema_tis_url
    assert_response :success
  end

  test "should get new" do
    get new_tipo_problema_ti_url
    assert_response :success
  end

  test "should create tipo_problema_ti" do
    assert_difference('TipoProblemaTi.count') do
      post tipo_problema_tis_url, params: { tipo_problema_ti: { descricao: @tipo_problema_ti.descricao, nome: @tipo_problema_ti.nome } }
    end

    assert_redirected_to tipo_problema_ti_url(TipoProblemaTi.last)
  end

  test "should show tipo_problema_ti" do
    get tipo_problema_ti_url(@tipo_problema_ti)
    assert_response :success
  end

  test "should get edit" do
    get edit_tipo_problema_ti_url(@tipo_problema_ti)
    assert_response :success
  end

  test "should update tipo_problema_ti" do
    patch tipo_problema_ti_url(@tipo_problema_ti), params: { tipo_problema_ti: { descricao: @tipo_problema_ti.descricao, nome: @tipo_problema_ti.nome } }
    assert_redirected_to tipo_problema_ti_url(@tipo_problema_ti)
  end

  test "should destroy tipo_problema_ti" do
    assert_difference('TipoProblemaTi.count', -1) do
      delete tipo_problema_ti_url(@tipo_problema_ti)
    end

    assert_redirected_to tipo_problema_tis_url
  end
end
