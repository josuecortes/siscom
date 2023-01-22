json.extract! requisicao_transporte, :id, :status, :user_id, :unidade_id, :tipo, :documento_viagem, :data_hora_ida, :data_hora_retorno, :motivo, :created_at, :updated_at
json.url requisicao_transporte_url(requisicao_transporte, format: :json)
