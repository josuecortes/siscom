class Acao < ApplicationRecord
  belongs_to :user
  has_many :acao_users
  has_many :etapas

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Finalizada": 3, "Paralizada": 4, "Cancelada": 5 }

end
