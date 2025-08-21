class MovimentacaoEquipamento < ApplicationRecord
  belongs_to :unidade_origem, class_name: 'Unidade'
  belongs_to :unidade_destino, class_name: 'Unidade'
  belongs_to :responsavel, class_name: 'User' # Usuário que receberá os equipamentos
  belongs_to :user, class_name: 'User' # Usuário que criou a movimentação
  has_many :item_movimentacoes, dependent: :destroy
  has_many :equipamentos, through: :item_movimentacoes

  validates :unidade_origem, presence: true
  validates :unidade_destino, presence: true
  validates :responsavel, presence: true
  validates :user, presence: true
  validates :status, presence: true, inclusion: { in: %w[em_andamento concluida cancelada] }
  validate :unidade_origem_diferente_destino
  validate :responsavel_deve_ter_permissao_req_serv_ti

  before_create :set_data_movimentacao

  scope :em_andamento, -> { where(status: 'em_andamento') }
  scope :concluidas, -> { where(status: 'concluida') }
  scope :por_responsavel, ->(user_id) { where(responsavel_id: user_id) }

  def equipamentos_pendentes
    item_movimentacoes.where(recebido: false, status: 'pendente')
  end

  def equipamentos_recebidos
    item_movimentacoes.where(recebido: true, status: 'recebido')
  end

  def total_equipamentos
    item_movimentacoes.count
  end

  def equipamentos_pendentes_count
    equipamentos_pendentes.count
  end

  def equipamentos_recebidos_count
    equipamentos_recebidos.count
  end

  def concluida?
    status == 'concluida'
  end

  def em_andamento?
    status == 'em_andamento'
  end

  def cancelada?
    status == 'cancelada'
  end

  def pode_ser_concluida?
    em_andamento? && equipamentos_pendentes_count == 0
  end

  def pode_ser_cancelada?
    em_andamento? && equipamentos_recebidos_count == 0
  end

  def cancelar_movimentacao(usuario)
    return false unless pode_ser_cancelada?
    return false unless user == usuario # Só quem criou pode cancelar
    
    ActiveRecord::Base.transaction do
      # Cancelar a movimentação
      update!(status: 'cancelada')
      
      # Cancelar todos os itens da movimentação
      item_movimentacoes.update_all(status: 'cancelada')
    end
    
    true
  rescue => e
    Rails.logger.error "Erro ao cancelar movimentação: #{e.message}"
    false
  end

  def concluir_movimentacao
    return false unless pode_ser_concluida?
    
    update(status: 'concluida')
  end

  def adicionar_equipamento(equipamento)
    return false if item_movimentacoes.exists?(equipamento: equipamento)
    
    # Verificar se o equipamento já está em uma movimentação em andamento
    # Equipamentos de movimentações canceladas podem ser incluídos em novas movimentações
    movimentacao_pendente = ItemMovimentacao.joins(:movimentacao_equipamento)
                                           .where(equipamento: equipamento)
                                           .where(status: 'pendente')
                                           .where(movimentacao_equipamentos: { status: 'em_andamento' })
                                           .exists?
    
    return false if movimentacao_pendente
    
    item_movimentacoes.create(equipamento: equipamento, status: 'pendente', recebido: false)
  end

  def receber_equipamento(equipamento, usuario_receptor)
    item = item_movimentacoes.find_by(equipamento: equipamento)
    return false unless item && item.status == 'pendente'

    ActiveRecord::Base.transaction do
      # Marcar como recebido
      item.update!(
        recebido: true,
        status: 'recebido',
        data_recebimento: Time.current
      )

      # Atualizar unidade do equipamento e registrar no histórico
      unidade_anterior = equipamento.unidade.sigla_nome
      equipamento.update!(unidade_id: unidade_destino.id)
      
      # Registrar movimentação no histórico do equipamento
      equipamento.adicionar_movimentacao(
        'movimentacao',
        "Movimentado de #{unidade_anterior} para #{unidade_destino.sigla_nome} - Movimentação ##{id}",
        {
          movimentacao_id: id,
          unidade_origem: unidade_anterior,
          unidade_destino: unidade_destino.sigla_nome,
          responsavel: responsavel.nome,
          usuario_receptor: usuario_receptor.nome,
          data_movimentacao: data_movimentacao
        }
      )

      # Verificar se todos os equipamentos foram recebidos
      concluir_movimentacao if equipamentos_pendentes_count == 0
    end

    true
  rescue => e
    Rails.logger.error "Erro ao receber equipamento: #{e.message}"
    false
  end

  private

  def unidade_origem_diferente_destino
    if unidade_origem_id == unidade_destino_id
      errors.add(:unidade_destino, "deve ser diferente da unidade de origem")
    end
  end

  def responsavel_deve_ter_permissao_req_serv_ti
    if responsavel.present? && !responsavel.has_role?(:req_serv_ti)
      errors.add(:responsavel, "deve ter permissão de req_serv_ti")
    end
  end

  def set_data_movimentacao
    self.data_movimentacao ||= Time.current
  end
end
