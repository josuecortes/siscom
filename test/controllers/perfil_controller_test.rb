require 'test_helper'

class PerfilControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get perfil_index_url
    assert_response :success
  end

  test "should get update" do
    get perfil_update_url
    assert_response :success
  end

end
