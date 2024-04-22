class Acao < ApplicationRecord
  attr_accessor :usuario_id

  has_many :acao_users
  has_many :etapas

  after_create :criar_gerente

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Finalizada": 3, "Paralizada": 4, "Cancelada": 5 }

  def criar_gerente
    AcaoUser.create(acao_id: self.id, user_id: self.usuario_id, nivel: 1, inicio: Time.now, status: 1)
  end
end
