module Transporte
  # Observação da operação ou do motorista sobre uma solicitação, com anexos.
  class Observacao < ApplicationRecord
    self.table_name = "transporte_observacoes"

    PAPEIS = { "tecnico" => "Operação", "motorista" => "Motorista" }.freeze

    belongs_to :solicitacao, class_name: "Transporte::Solicitacao", inverse_of: :observacoes
    belongs_to :autor, class_name: "User"
    has_many_attached :anexos

    normalizes :corpo, with: ->(corpo) { corpo.to_s.strip }

    validates :corpo, presence: true, length: { maximum: 2000 }
    validates :papel, inclusion: { in: PAPEIS.keys }

    scope :em_ordem, -> { order(:created_at, :id) }

    def nome_do_papel = PAPEIS[papel]
  end
end
