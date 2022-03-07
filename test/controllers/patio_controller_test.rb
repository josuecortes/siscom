require 'test_helper'

class PatioControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get patio_index_url
    assert_response :success
  end

end
