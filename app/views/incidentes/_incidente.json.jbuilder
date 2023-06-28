json.extract! incidente, :id, :descricao, :texto_explicativo, :previsao_de_retorno, :data_hora_inicio, :data_hora_fim, :ativo, :created_at, :updated_at
json.url incidente_url(incidente, format: :json)
