module Core
  # Contexto da requisição atual (quem está agindo e de onde), preenchido pelo
  # ApplicationController e usado pela auditoria. Zera sozinho a cada requisição.
  class Contexto < ActiveSupport::CurrentAttributes
    attribute :ator, :ip, :request_id
  end
end
