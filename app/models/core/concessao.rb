module Core
  # Concessão: o usuário tem um papel num módulo, opcionalmente limitado a um
  # escopo (ex.: escopo_tipo "rh_unidade" + escopo_id). Revogar = status inativo
  # (o registro fica como histórico).
  class Concessao < ApplicationRecord
    self.table_name = "core_concessoes"

    STATUS = %w[ativo inativo].freeze

    belongs_to :acesso, class_name: "Core::Acesso"
    belongs_to :user, class_name: "::User"
    belongs_to :concedido_por, class_name: "::User", optional: true

    enum :status, STATUS.index_by(&:itself), validate: true

    validates :modulo, :papel, presence: true
    validates :escopo_tipo, presence: true, if: :escopo_id?
    validates :escopo_id, presence: true, if: :escopo_tipo?
    validate :papel_no_catalogo
    validate :coerente_com_acesso
    validate :unica_quando_ativa

    after_commit { Core::Autorizacao.esquecer(user_id) }

    def global? = escopo_id.nil?

    def papel_do_catalogo
      Core::Catalogo.modulo(modulo)&.papel(papel)
    end

    private

    def papel_no_catalogo
      return if modulo.blank? || papel.blank?

      errors.add(:papel, :inclusion) unless papel_do_catalogo
    end

    def coerente_com_acesso
      return unless acesso

      errors.add(:acesso, :invalid) if acesso.user_id != user_id || acesso.modulo != modulo
    end

    def unica_quando_ativa
      return unless ativo?

      repetida = self.class.ativo.where(user_id:, modulo:, papel:, escopo_tipo:, escopo_id:).where.not(id:)
      errors.add(:papel, :taken) if repetida.exists?
    end
  end
end
