class RequisicaoTransporte < ApplicationRecord
  attr_accessor :dia_requisicao_normal_urgente
  attr_accessor :hora_requisicao_normal_urgente

  belongs_to :user
  belongs_to :unidade

  has_one_attached :documento

  has_one :servico_transporte, dependent: :destroy

  has_many :passageiros, dependent: :destroy
  has_many :destinos, dependent: :destroy

  accepts_nested_attributes_for :passageiros, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :destinos, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :motivo, :passageiros, :destinos
  validate :validar_documento, on: :create

  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }

  enum status: { aguardando: 1, aprovada: 2, em_servico: 3, negada: 4, cancelada: 5, finalizada: 6 }
  enum tipo: { urgente: 1, normal: 2, viagem: 3 }

  before_validation :ajustar_datahora_saida, on: :create
  before_validation :validar_data_normal, on: :create
  before_validation :validar_data_viagem, on: :create

  def validar_documento
    if documento.attached? && documento.blob.byte_size > 1.megabyte
      errors.add(:documento, "O tamanho é muito grande. O arquivo deve ser menor que 1MB.")
    end
  end
  
  def ajustar_datahora_saida
    if self.dia_requisicao_normal_urgente and self.hora_requisicao_normal_urgente
      self.data_hora_ida = "#{self.dia_requisicao_normal_urgente} #{self.hora_requisicao_normal_urgente}"
      if self.data_hora_ida <= Time.now
        self.errors.add(:hora_requisicao_normal_urgente, "Data/hora de ida não pode ser menor que a data/hora atual.")
      end
    end
  end

  def validar_data_viagem
    if self.tipo == "viagem"
      validates_presence_of :documento
      if self.data_hora_ida.present? and self.data_hora_retorno.present?
        data_viagem = (Time.now + 3.days).beginning_of_day
        if self.data_hora_ida < data_viagem
          self.errors.add(:data_hora_ida, "Data de ida não pode ser menor que #{data_viagem.strftime('%d/%m/%Y %H:%M')}.")
        end
        if self.data_hora_ida >= self.data_hora_retorno
          self.errors.add(:data_hora_ida, "Data de ida não pode ser menor que a data de volta.")
        end
      end
    end
  end

  def validar_data_normal
    if self.tipo == "normal"
      validates_presence_of :data_hora_ida
      if self.data_hora_ida.present?
        data = (Time.now + 1.day).beginning_of_day
        if self.data_hora_ida < data
          self.errors.add(:data_hora_ida, "Data de ida não pode ser menor que #{data.strftime('%d/%m/%Y %H:%M')}.")
        end
      end
    end
  end

  def mudar_status(status, usuario = nil)
    self.status = status
    if status == "em_servico"
      self.usuario_em_servico = usuario if usuario
      self.data_hora_em_servico = Time.now
    elsif status == "finalizada"
      self.usuario_finalizou = usuario if usuario
      self.data_hora_finalizada = Time.now
    end
    self.save
  end
end
