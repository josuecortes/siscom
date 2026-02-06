class Tarefa < ApplicationRecord
  attr_accessor :usuario_logado_id

  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true
  has_many :comentarios, class_name: 'TarefaComentario', dependent: :destroy

  validates_presence_of :user_id, :titulo, :descricao, :prioridade, :status, :tipo

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Impedimento": 3, "Concluída": 4 }
  enum tipo: { "Pessoal": 1, "Unidade": 2, "Ação/Etapa": 3 }
  enum prioridade: { "Muito Alta": 1, "Alta": 2, "Normal": 3, "Baixa": 4, "Muito Baixa": 5 }

  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }

  before_validation :verificar_user

  def editable_by?(user)
    user && (user.id == user_id || user.id == created_by_id)
  end

  def verificar_user
    if self.tipo == "Pessoal" or self.tipo == 1
      self.user_id = self.usuario_logado_id if self.usuario_logado_id and (self.user_id != self.usuario_logado_id)
    end
  end
end
