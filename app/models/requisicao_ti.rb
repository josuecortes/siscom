class RequisicaoTi < ApplicationRecord
  belongs_to :user
  belongs_to :tecnico, class_name: 'User', foreign_key: 'tecnico_id', optional: true
  belongs_to :unidade
  belongs_to :problema_ti
  # belongs_to :unidade
  belongs_to :cargo, optional: true
  belongs_to :funcao, optional: true

  has_many :mensagens

  validates_presence_of :user_id, :problema_ti_id
  validates_presence_of :tecnico_id, if: Proc.new{ |r| r.status.in? ['Em atendimento', 'Concluída', 'Finalizada'] }
  # validates_presence_of :observacoes, on: :create
  validates_presence_of :solucao, if: Proc.new{ |r| r.status == 'Concluída' }
  validates_presence_of :avaliacao, if: Proc.new{ |r| r.status == 'Finalizada' }
  validates_presence_of :comentario, if: Proc.new{ |r| r.avaliacao.in? ['Péssimo', 'Ruim'] }
  validate :verificar_requisicao_sistemas
  validate :verificar_requisicao_sistemas_problemas, on: :create

  enum status: { "Solicitada": 1,  "Em atendimento": 2, "Concluída": 3, "Cancelada": 4, "Finalizada": 5 }
  enum avaliacao: { "Muito Bom": 5,  "Bom": 4, "Normal": 3, "Ruim": 2, "Péssimo": 1 }

  scope :do_usuario, ->(id) { where("user_id = ?", id) }
  scope :do_tecnico, ->(id) { where("tecnico_id = ?", id) }
  scope :com_status, ->(status) { where("status = ?", status) }
  scope :do_usuario_ou_tecnico, ->(id) { where("user_id = ? or tecnico_id = ?", id, id) }
  scope :pode_enviar_mensagem, -> { where("status = ? or status = ?", 2, 3) }

  def verificar_requisicao_sistemas_problemas
    return true unless self.problema_ti
    problema_ti = ProblemaTi.find(self.problema_ti_id)
    return true unless problema_ti

    case problema_ti.nome
      when 'PRODOC - PROBLEMAS'
        validates_presence_of :observacoes
      when 'WEBMAIL - PROBLEMAS'
        validates_presence_of :observacoes
      when 'SISCOM - PROBLEMAS'
        validates_presence_of :observacoes
      when 'SIGDOC - PROBLEMAS'
        validates_presence_of :observacoes
    end
  end

  def verificar_requisicao_sistemas
    return true unless self.problema_ti

    problema_ti = ProblemaTi.find(self.problema_ti_id)
    return true unless problema_ti.tipo_problema_ti_id == 3

    case problema_ti.nome
      when 'PRODOC - CADASTRO'
        validates_presence_of :nome, :email, :cpf, :rg, :data_nascimento, :celular, :cargo_id, :funcao_id, :estado, :municipio, :perfil
      when 'PRODOC - SUBSTITUIÇÃO'
        validates_presence_of :nome, :email, :periodo_inicio, :periodo_fim
      when 'PRODOC - RETIRADA'
        validates_presence_of :nome, :email
      when 'PRODOC - TROCAR SENHA'
        validates_presence_of :nome, :email
      when 'PRODOC - ALTERAR PERFIL'
        validates_presence_of :nome, :email, :perfil
      when 'PRODOC - LIBERAR ACESSO'
        validates_presence_of :nome, :email, :funcao_id, :perfil, :periodo_inicio, :periodo_fim
      when 'PRODOC - PROBLEMAS'
        validates_presence_of :observacoes
      when 'WEBMAIL - CADASTRO'
        validates_presence_of :nome, :funcao_id, :email, :unidade_id
      when 'WEBMAIL - TROCAR SENHA'
        validates_presence_of :nome, :email
      when 'WEBMAIL - PROBLEMAS'
        validates_presence_of :observacoes
      when 'SISCOM - CADASTRO'
        validates_presence_of :nome, :funcao_id, :unidade_id, :email
      when 'SISCOM - TROCAR SENHA'
        validates_presence_of :nome, :email
      when 'SISCOM - PROBLEMAS'
        validates_presence_of :observacoes
      when 'SIGDOC - SOLICITAR PERMISSÃO DE ACESSO'
        validates_presence_of :nome, :email, :unidade
      when 'SIGDOC - DESABILITAR PERMISSÃO'
        validates_presence_of :nome, :email
      when 'SIGDOC - PROBLEMAS'
        validates_presence_of :observacoes
    end

  end

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

  def mensagens_nao_lidas(user)
    self.mensagens.where('user_id != ? and status = ?', user, 'não lida').count
  end

  def self.finalizar_requisicoes(user)
    cont_finalizadas = 0
    RequisicaoTi.do_usuario(user).where("status = ? and data_hora_concluida < ?", 3, (DateTime.now - 36.hours)).each do |r|
      r.status = 'Finalizada'
      r.avaliacao = 'Muito Bom'
      r.comentario = 'Requisição finalizada automaticamente pelo sistema após o prazo de 48 horas.'
      r.data_hora_finalizada = DateTime.now
      if r.save
        cont_finalizadas += 1
      end
    end
    return cont_finalizadas
  end

  def self.requisicoes_a_finalizar(user)
    cont_a_finalizar = RequisicaoTi.do_usuario(user).where("status = ?", 3).count
    return cont_a_finalizar
  end

  def self.atualizar_mensagens_nao_lidas(user)
    RequisicaoTi.do_usuario(user).where("status = ? or status = ?", 3, 5).each do |r|
      r.mensagens.each do |m|
        m.status = "lida"
        m.save
      end
    end
  end

end
