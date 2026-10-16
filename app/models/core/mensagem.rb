module Core
  # Mensagem de uma conversa: de uma pessoa (texto) ou do sistema (ex.: mudança de etapa).
  class Mensagem < ApplicationRecord
    self.table_name = "core_mensagens"

    TIPOS = %w[texto sistema].freeze
    TAMANHO_MAXIMO = 2000

    belongs_to :conversa, class_name: "Core::Conversa", inverse_of: :mensagens
    belongs_to :autor, class_name: "::User", optional: true

    normalizes :corpo, with: ->(corpo) { corpo.to_s.strip }

    validates :tipo, inclusion: { in: TIPOS }
    validates :corpo, presence: true, length: { maximum: TAMANHO_MAXIMO }

    scope :em_ordem, -> { order(:id) }

    def do_sistema? = tipo == "sistema"
  end
end
