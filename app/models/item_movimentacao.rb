class ItemMovimentacao < ApplicationRecord
  belongs_to :movimentacao_equipamento
  belongs_to :equipamento

  validates :movimentacao_equipamento, presence: true
  validates :equipamento, presence: true
  validates :recebido, inclusion: { in: [true, false] }
  validates :status, inclusion: { in: %w[pendente recebido cancelada] }, allow_nil: true

  scope :pendentes, -> { where(recebido: false, status: 'pendente') }
  scope :recebidos, -> { where(recebido: true, status: 'recebido') }
  scope :cancelados, -> { where(status: 'cancelada') }

  def pendente?
    !recebido?
  end

  def recebido?
    recebido == true
  end

  def receber!
    return false if recebido?

    update!(
      recebido: true,
      status: 'recebido',
      data_recebimento: Time.current
    )
  end

  def cancelado?
    status == 'cancelada'
  end
end
