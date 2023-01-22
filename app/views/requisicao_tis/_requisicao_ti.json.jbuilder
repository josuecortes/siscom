json.extract! requisicao_ti, :id, :status, :user_id, :unidade_id, :problema_ti_id, :observacoes, :solucao, :created_at, :updated_at
json.url requisicao_ti_url(requisicao_ti, format: :json)
