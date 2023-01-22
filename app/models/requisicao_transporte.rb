class RequisicaoTransporte < ApplicationRecord
  attr_accessor :dia_requisicao_normal_urgente
  attr_accessor :hora_requisicao_normal_urgente

  belongs_to :user
  belongs_to :unidade

  has_one :servico_transporte, dependent: :destroy

  has_many :passageiros, dependent: :destroy
  has_many :destinos, dependent: :destroy

  accepts_nested_attributes_for :passageiros, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :destinos, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :passageiros, :destinos

  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }

  enum status: { aguardando: 1, aprovada: 2, em_servico: 3, negada: 4, cancelada: 5, finalizada: 6 }
  enum tipo: { urgente: 1, normal: 2, viagem: 3 }

  before_validation :ajustar_datahora_saida
  
  def ajustar_datahora_saida
    if self.dia_requisicao_normal_urgente and self.hora_requisicao_normal_urgente
      self.data_hora_ida = "#{self.dia_requisicao_normal_urgente} #{self.hora_requisicao_normal_urgente}"
    end
  end

  def mudar_status(status)
    self.status = status
    self.save
  end
end
