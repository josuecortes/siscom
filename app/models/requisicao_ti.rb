class RequisicaoTi < ApplicationRecord
  belongs_to :user
  belongs_to :tecnico, class_name: 'User', foreign_key: 'tecnico_id', optional: true
  belongs_to :departamento
  belongs_to :problema_ti

  validates_presence_of :user_id, :problema_ti_id
  validates_presence_of :tecnico_id, if: Proc.new{ |r| r.status.in? ['Em atendimento', 'Concluída', 'Finalizada'] }
  validates_presence_of :solucao, if: Proc.new{ |r| r.status == 'Concluída' }
  validates_presence_of :avaliacao, if: Proc.new{ |r| r.status == 'Finalizada' }
  validates_presence_of :comentario, if: Proc.new{ |r| r.avaliacao.in? ['Péssimo', 'Ruim'] }

  

  
  enum status: { "Solicitada": 1,  "Em atendimento": 2, "Concluída": 3, "Cancelada": 4, "Finalizada": 5 }
  enum avaliacao: { "Muito Bom": 5,  "Bom": 4, "Normal": 3, "Ruim": 2, "Péssimo": 1 }
  
  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :do_tecnico, ->(id) { where("tecnico_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }

  def pode_ser_editada
    return true if self.status == 1

    false
  end

  def pode_ser_concluida(user)
    return true if self.status == 2 and self.tecnico == user

    false
  end

  def pode_ser_finalizada(user)
    return true if self.status == 3 and self.user == user

    false
  end
  

end
