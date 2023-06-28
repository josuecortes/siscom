require 'test_helper'

class IncidentesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @incidente = incidentes(:one)
  end

  test "should get index" do
    get incidentes_url
    assert_response :success
  end

  test "should get new" do
    get new_incidente_url
    assert_response :success
  end

  test "should create incidente" do
    assert_difference('Incidente.count') do
      post incidentes_url, params: { incidente: { ativo: @incidente.ativo, data_hora_fim: @incidente.data_hora_fim, data_hora_inicio: @incidente.data_hora_inicio, descricao: @incidente.descricao, previsao_de_retorno: @incidente.previsao_de_retorno, texto_explicativo: @incidente.texto_explicativo } }
    end

    assert_redirected_to incidente_url(Incidente.last)
  end

  test "should show incidente" do
    get incidente_url(@incidente)
    assert_response :success
  end

  test "should get edit" do
    get edit_incidente_url(@incidente)
    assert_response :success
  end

  test "should update incidente" do
    patch incidente_url(@incidente), params: { incidente: { ativo: @incidente.ativo, data_hora_fim: @incidente.data_hora_fim, data_hora_inicio: @incidente.data_hora_inicio, descricao: @incidente.descricao, previsao_de_retorno: @incidente.previsao_de_retorno, texto_explicativo: @incidente.texto_explicativo } }
    assert_redirected_to incidente_url(@incidente)
  end

  test "should destroy incidente" do
    assert_difference('Incidente.count', -1) do
      delete incidente_url(@incidente)
    end

    assert_redirected_to incidentes_url
  end
end
