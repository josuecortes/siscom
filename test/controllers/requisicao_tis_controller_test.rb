require 'test_helper'

class RequisicaoTisControllerTest < ActionDispatch::IntegrationTest
  setup do
    @requisicao_ti = requisicao_tis(:one)
  end

  test "should get index" do
    get requisicao_tis_url
    assert_response :success
  end

  test "should get new" do
    get new_requisicao_ti_url
    assert_response :success
  end

  test "should create requisicao_ti" do
    assert_difference('RequisicaoTi.count') do
      post requisicao_tis_url, params: { requisicao_ti: { unidade_id: @requisicao_ti.unidade_id, observacoes: @requisicao_ti.observacoes, problema_ti_id: @requisicao_ti.problema_ti_id, solucao: @requisicao_ti.solucao, status: @requisicao_ti.status, user_id: @requisicao_ti.user_id } }
    end

    assert_redirected_to requisicao_ti_url(RequisicaoTi.last)
  end

  test "should show requisicao_ti" do
    get requisicao_ti_url(@requisicao_ti)
    assert_response :success
  end

  test "should get edit" do
    get edit_requisicao_ti_url(@requisicao_ti)
    assert_response :success
  end

  test "should update requisicao_ti" do
    patch requisicao_ti_url(@requisicao_ti), params: { requisicao_ti: { unidade_id: @requisicao_ti.unidade_id, observacoes: @requisicao_ti.observacoes, problema_ti_id: @requisicao_ti.problema_ti_id, solucao: @requisicao_ti.solucao, status: @requisicao_ti.status, user_id: @requisicao_ti.user_id } }
    assert_redirected_to requisicao_ti_url(@requisicao_ti)
  end

  test "should destroy requisicao_ti" do
    assert_difference('RequisicaoTi.count', -1) do
      delete requisicao_ti_url(@requisicao_ti)
    end

    assert_redirected_to requisicao_tis_url
  end
end
