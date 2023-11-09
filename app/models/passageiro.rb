class Passageiro < ApplicationRecord
  belongs_to :requisicao_transporte, optional: true
  belongs_to :user, optional: true

  validates_presence_of :nome, :cpf
  
  before_save :upcase_fields

  def upcase_fields
    self.nome.upcase!
  end
end
