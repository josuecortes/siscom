require 'test_helper'

class MovimentacaoEquipamentosControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get movimentacao_equipamentos_index_url
    assert_response :success
  end

  test "should get new" do
    get movimentacao_equipamentos_new_url
    assert_response :success
  end

  test "should get create" do
    get movimentacao_equipamentos_create_url
    assert_response :success
  end

  test "should get show" do
    get movimentacao_equipamentos_show_url
    assert_response :success
  end

  test "should get receber_equipamento" do
    get movimentacao_equipamentos_receber_equipamento_url
    assert_response :success
  end

end
