json.extract! acao, :id, :nome, :descricao, :inicio, :fim, :motivacao, :orcamento, :status, :mostrar_no_site, :created_at, :updated_at
json.url acao_url(acao, format: :json)
