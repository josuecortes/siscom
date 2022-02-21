json.extract! passageiro, :id, :nome, :celular, :cpf, :requisicao_transporte_id, :user_id, :created_at, :updated_at
json.url passageiro_url(passageiro, format: :json)
