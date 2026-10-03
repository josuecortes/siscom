module Core
  # Notificação para um usuário (porta de notification.rb do seed).
  class Notificacao < ApplicationRecord
    self.table_name = "core_notificacoes"

    belongs_to :user, class_name: "::User"
    belongs_to :ator, class_name: "::User", optional: true

    validates :modulo, :evento, :titulo, presence: true

    scope :recentes, -> { order(created_at: :desc, id: :desc) }
    scope :nao_lidas, -> { where(lida_em: nil) }
    scope :buscar, lambda { |termo|
      padrao = "%#{sanitize_sql_like(termo.to_s.squish)}%"
      where("titulo ILIKE :p OR mensagem ILIKE :p", p: padrao)
    }

    def lida? = lida_em.present?

    def nome_do_modulo = Core::Catalogo.modulo(modulo)&.nome || modulo

    def nome_do_ator = ator&.nome || "Sistema"
  end
end
