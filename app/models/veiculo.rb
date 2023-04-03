class Veiculo < ApplicationRecord
  validates_presence_of :placa, :marca, :modelo, :combustivel, :capacidade, :carga, :status
  validates_uniqueness_of :placa

  belongs_to :motorista, optional: true

  has_many :servico_transportes, dependent: :destroy

  enum status: { garagem: 1, patio: 2, em_servico: 3 }

  scope :com_status, -> (status) { where("status = ?", status) }

  before_validation :novo_veiculo, on: :create

  def novo_veiculo
    self.status = 1
  end

  def mudar_status(status)
    self.status = status
    self.motorista_id = nil if status == 'garagem'
    self.save
  end
end