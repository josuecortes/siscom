require 'test_helper'

class EtapasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @etapa = etapas(:one)
  end

  test "should get index" do
    get etapas_url
    assert_response :success
  end

  test "should get new" do
    get new_etapa_url
    assert_response :success
  end

  test "should create etapa" do
    assert_difference('Etapa.count') do
      post etapas_url, params: { etapa: {  } }
    end

    assert_redirected_to etapa_url(Etapa.last)
  end

  test "should show etapa" do
    get etapa_url(@etapa)
    assert_response :success
  end

  test "should get edit" do
    get edit_etapa_url(@etapa)
    assert_response :success
  end

  test "should update etapa" do
    patch etapa_url(@etapa), params: { etapa: {  } }
    assert_redirected_to etapa_url(@etapa)
  end

  test "should destroy etapa" do
    assert_difference('Etapa.count', -1) do
      delete etapa_url(@etapa)
    end

    assert_redirected_to etapas_url
  end
end
