json.extract! destino, :id, :tipo, :descricao, :cep, :numero, :cidade, :bairro, :logradouro, :requisicao_transporte_id, :user_id, :created_at, :updated_at
json.url destino_url(destino, format: :json)
