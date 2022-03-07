class Motorista < ApplicationRecord
  validates_presence_of :nome, :cpf, :data_nascimento, :cnh, :validade_cnh
  validates_uniqueness_of :cpf, :cnh

  has_one :veiculo

  has_many :servico_transportes, dependent: :destroy

  enum status: { garagem: 1, em_servico: 2 }

  scope :com_status, ->(status) { where("status = ?", status) }

  before_validation :novo_motorista, on: :create

  def novo_motorista
    self.status = 1
  end
end
