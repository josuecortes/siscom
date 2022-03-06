class Passageiro < ApplicationRecord
  belongs_to :requisicao_transporte, optional: true
  belongs_to :user, optional: true

  validates_presence_of :nome, :cpf
  # validates_uniqueness_of :cpf
end
