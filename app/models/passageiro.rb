class Passageiro < ApplicationRecord
  belongs_to :requisicao_transporte
  belongs_to :user

  validates_presence_of :nome, :celular, :cpf, :requisicao_transporte_id, :user_id
  validates_uniqueness_of :cpf
end
