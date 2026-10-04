module Ti
  # Linha do tempo do chamado: quem fez o quê e quando.
  class EventoChamado < ApplicationRecord
    self.table_name = "ti_eventos_chamado"

    TIPOS = %w[aberto assumido triado encaminhado etapa_alterada prioridade_alterada reenviado concluido finalizado cancelado reaberto].freeze

    belongs_to :chamado, class_name: "Ti::Chamado", inverse_of: :eventos
    belongs_to :ator, class_name: "User", optional: true

    validates :tipo, inclusion: { in: TIPOS }
    validates :ocorrido_em, presence: true

    scope :em_ordem, -> { order(:ocorrido_em, :id) }
  end
end
