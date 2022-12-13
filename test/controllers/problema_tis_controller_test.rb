require 'test_helper'

class ProblemaTisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @problema_ti = problema_tis(:one)
  end

  test "should get index" do
    get problema_tis_url
    assert_response :success
  end

  test "should get new" do
    get new_problema_ti_url
    assert_response :success
  end

  test "should create problema_ti" do
    assert_difference('ProblemaTi.count') do
      post problema_tis_url, params: { problema_ti: { descricao: @problema_ti.descricao, nome: @problema_ti.nome, tipo_problema_ti_id: @problema_ti.tipo_problema_ti_id } }
    end

    assert_redirected_to problema_ti_url(ProblemaTi.last)
  end

  test "should show problema_ti" do
    get problema_ti_url(@problema_ti)
    assert_response :success
  end

  test "should get edit" do
    get edit_problema_ti_url(@problema_ti)
    assert_response :success
  end

  test "should update problema_ti" do
    patch problema_ti_url(@problema_ti), params: { problema_ti: { descricao: @problema_ti.descricao, nome: @problema_ti.nome, tipo_problema_ti_id: @problema_ti.tipo_problema_ti_id } }
    assert_redirected_to problema_ti_url(@problema_ti)
  end

  test "should destroy problema_ti" do
    assert_difference('ProblemaTi.count', -1) do
      delete problema_ti_url(@problema_ti)
    end

    assert_redirected_to problema_tis_url
  end
end
