class Destino < ApplicationRecord
  belongs_to :requisicao_transporte, optional: true
  belongs_to :user, optional: true

  validates_presence_of :cep, :numero, :descricao

  before_save :upcase_fields

  def upcase_fields
    self.descricao.upcase!
  end

end
