class Veiculo < ApplicationRecord
  validates_presence_of :placa, :marca, :modelo, :combustivel, :capacidade, :carga, :status, :nome
  validates_uniqueness_of :placa

  belongs_to :motorista, optional: true

  has_many :servico_transportes, dependent: :destroy

  enum status: { garagem: 1, patio: 2, em_servico: 3 }
  enum combustivel: { "Gasolina": 1,  "Álcool": 2, "Diesel": 3, "Gasolina/Álcool": 4, "Elétrico": 5 }
  enum carga: { "Sim": 1,  "Não": 2 }
  enum capacidade: { "1 Lugar": 1,  "5 Lugares": 2, "7 Lugares": 3, "Mais de 7 lugares": 4 }

  scope :com_status, -> (status) { where("status = ?", status) }

  before_validation :novo_veiculo, on: :create
  before_save :upcase_fields

   def upcase_fields
      self.placa.upcase!
      self.marca.upcase!
      self.modelo.upcase!
      self.nome.upcase!
   end

  def novo_veiculo
    self.status = 1
  end

  def mudar_status(status)
    self.status = status
    self.motorista_id = nil if status == 'garagem'
    self.save
  end
end