class TransporteEscolar::Veiculo < ApplicationRecord
  attr_accessor :tipo_identificacao

  belongs_to :transportador, class_name: 'TransporteEscolar::Transportador'
  belongs_to :condutor, class_name: 'TransporteEscolar::Condutor'

  validates_presence_of :procedencia, :tipo, :identificacao, :transportador_id, :condutor_id, :capacidade_carga, :capacidade_pessoas
  validates_uniqueness_of :identificacao
  
  enum procedencia: { "Terrestre": 1,  "Fluvial": 2 }  
  enum tipo: {
    "Barco": 1,
    "Caminhão": 2,
    "Carro": 3,
    "Catraia": 4,
    "Catraio": 5,
    "Comte": 6,
    "Kombi": 7,
    "Lancha": 8,
    "Micro Ônibus": 9,
    "Ônibus": 10,
    "Rabeta": 11,
    "Van": 12
  }
  enum capacidade_carga: { "SIM": 1,  "NÃO": 2 }  

  before_save :upcase_fields

  def tipo_identificacao
    "#{tipo} - #{identificacao}"
  end
  def upcase_fields
    self.ano.upcase! if self.ano
    self.identificacao.upcase! if self.identificacao
    self.modelo.upcase! if self.modelo
    self.marca.upcase! if self.marca
  end
end
