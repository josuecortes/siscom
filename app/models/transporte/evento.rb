module Transporte
  # Linha do histórico da solicitação: quem fez o quê e quando. O solicitante também vê.
  class Evento < ApplicationRecord
    self.table_name = "transporte_eventos"

    TIPOS = { "aberta" => "Solicitação aberta", "editada" => "Solicitação editada", "aprovada" => "Solicitação aprovada",
              "reagendada" => "Reagendamento proposto", "reagendamento_aceito" => "Reagendamento aceito",
              "reagendamento_recusado" => "Reagendamento recusado", "busca_reagendada" => "Busca reagendada",
              "servico_iniciado" => "Serviço iniciado", "trecho_finalizado" => "Trecho finalizado", "concluida" => "Serviço concluído",
              "cancelada" => "Solicitação cancelada" }.freeze

    belongs_to :solicitacao, class_name: "Transporte::Solicitacao", inverse_of: :eventos
    belongs_to :ator, class_name: "User", optional: true

    validates :tipo, inclusion: { in: TIPOS.keys }
    validates :ocorrido_em, presence: true

    scope :em_ordem, -> { order(:ocorrido_em, :id) }

    def titulo = TIPOS[tipo]
  end
end
