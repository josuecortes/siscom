require 'test_helper'

class NuinfoRequisicaoTisControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get nuinfo_requisicao_tis_index_url
    assert_response :success
  end

  test "should get show" do
    get nuinfo_requisicao_tis_show_url
    assert_response :success
  end

end
