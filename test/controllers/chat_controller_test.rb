require 'test_helper'

class ChatControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get chat_index_url
    assert_response :success
  end

  test "should get new" do
    get chat_new_url
    assert_response :success
  end

  test "should get refresh" do
    get chat_refresh_url
    assert_response :success
  end

end
