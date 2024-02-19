class TransporteEscolar::Escola < ApplicationRecord
  # fiels:
  # t.string "codigo"
  # t.string "nome", presence, unique
  # t.bigint "municipio_id", references, presence
  # t.string "bairro"
  # t.string "logradouro"
  # t.string "numero"
  # t.string "cep"

  belongs_to :municipio, class_name: 'TransporteEscolar::Municipio'
  
  validates_presence_of :nome, :municipio_id
  validates_uniqueness_of :nome

  before_save :upcase_fields

  def upcase_fields
    self.nome.upcase!
    self.bairro.upcase!
    self.logradouro.upcase!
    self.numero.upcase!
  end

end
