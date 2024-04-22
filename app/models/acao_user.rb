class AcaoUser < ApplicationRecord
  
  belongs_to :user
  belongs_to :acao

  validates_presence_of :user_id, :acao_id, :nivel, :status, :inicio
  validates_uniqueness_of :user_id, scope: [:acao_id, :nivel]

  enum status: { "Ativo": 1, "Inativo": 2 }
  enum nivel: { "Gerente": 1, "Gerente Funcional": 2, "Especialista Técnico": 3, "Profissional Especializado": 4, "Implementador": 5 }
end
