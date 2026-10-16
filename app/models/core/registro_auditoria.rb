module Core
  # Um registro de auditoria. Só inserção: não pode ser alterado nem apagado.
  class RegistroAuditoria < ApplicationRecord
    self.table_name = "core_registros_auditoria"

    belongs_to :ator, class_name: "::User", optional: true

    validates :modulo, :evento, presence: true

    scope :recentes, -> { order(created_at: :desc, id: :desc) }
    scope :do_modulo, ->(modulo) { where(modulo: modulo) }
    scope :do_evento, ->(evento) { where(evento: evento) }
    scope :do_alvo, ->(alvo) { where(alvo_tipo: alvo.class.name, alvo_id: alvo.id) }
    scope :entre, lambda { |inicio, fim|
      relacao = all
      relacao = relacao.where(created_at: inicio.beginning_of_day..) if inicio
      relacao = relacao.where(created_at: ..fim.end_of_day) if fim
      relacao
    }
    scope :buscar, lambda { |termo|
      where(Busca.em("ator_nome", "alvo_descricao"), t: Busca.padrao(termo))
    }

    def readonly? = persisted?

    def self.delete_all(*) = raise(ActiveRecord::ReadOnlyRecord, "auditoria não pode ser apagada")
    def self.update_all(*) = raise(ActiveRecord::ReadOnlyRecord, "auditoria não pode ser alterada")

    # "core.usuario.criado" => "Usuário cadastrado" (config/locales/auditoria.pt-BR.yml)
    def self.rotulo_do_evento(modulo, evento)
      I18n.t("auditoria.eventos.#{modulo}.#{evento}", default: evento.to_s.tr("._", "  ").capitalize)
    end

    def rotulo = self.class.rotulo_do_evento(modulo, evento)

    def nome_do_ator = ator_nome.presence || "Sistema"
  end
end
