class Motorista < ApplicationRecord
  validates_presence_of :nome, :cpf, :data_nascimento, :cnh, :validade_cnh
  validates_uniqueness_of :cpf, :cnh

  has_many :servico_transportes, dependent: :destroy
end
