class TransporteEscolar::Municipio < ApplicationRecord
  attr_accessor :nome_tipo

  has_many :escolas, class_name: 'TransporteEscolar::Escola', dependent: :restrict_with_error
  has_many :transportadores, class_name: 'TransporteEscolar::Transportador', dependent: :restrict_with_error
  has_many :condutores, class_name: 'TransporteEscolar::Condutor', dependent: :restrict_with_error
  
  validates_presence_of :nome
  validates_uniqueness_of :nome

  enum tipo: { "URBANO": 1,  "RURAL": 2, "MACAPÁ - URBANA": 3, "MACAPÁ - RURAL": 4 }

  def nome_tipo
    return nome unless tipo

    "#{nome} - #{tipo}"
  end
end
