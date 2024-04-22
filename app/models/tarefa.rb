class Tarefa < ApplicationRecord
  attr_accessor :usuario_logado_id

  belongs_to :etapa, optional: true
  belongs_to :user

  validates_presence_of :user_id, :titulo, :descricao, :prioridade, :status, :tipo
  validates_presence_of :etapa_id, if: -> { tipo == "Ação/Etapa" || tipo == 3 }

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Impedimento": 3, "Concluída": 4 }
  enum tipo: { "Pessoal": 1, "Unidade": 2, "Ação/Etapa": 3 }
  enum prioridade: { "Muito Alta": 1, "Alta": 2, "Normal": 3, "Baixa": 4, "Muito Baixa": 5 }

  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }

  before_validation :verificar_user
  before_save :verificacoes

  def verificar_user
    if self.tipo == "Pessoal" or self.tipo == 1
      self.user_id = self.usuario_logado_id if self.usuario_logado_id and (self.user_id != self.usuario_logado_id)
      self.etapa = nil
    end
  end
  def verificacoes
    if self.tipo == "Pessoal" or self.tipo == 1
      self.user_id = self.usuario_logado_id if self.usuario_logado_id and (self.user_id != self.usuario_logado_id)
      self.etapa = nil
    elsif self.tipo == "Unidade" or self.tipo == 2
      self.etapa = nil
    end
  end
end
