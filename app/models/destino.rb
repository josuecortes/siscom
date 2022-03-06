class Destino < ApplicationRecord
  belongs_to :requisicao_transporte, optional: true
  belongs_to :user, optional: true

  validate_presence_of :cep, :numero, :descricao

end
