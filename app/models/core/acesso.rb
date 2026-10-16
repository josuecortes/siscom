module Core
  # Acesso de um usuário a um módulo. Sem registro, vale a regra do catálogo
  # (módulo com papel automático é aberto a todo usuário ativo); com registro
  # inativo, o usuário está bloqueado naquele módulo.
  class Acesso < ApplicationRecord
    self.table_name = "core_acessos"

    STATUS = %w[ativo inativo].freeze

    belongs_to :user, class_name: "::User"
    has_many :concessoes, class_name: "Core::Concessao", dependent: :restrict_with_error

    enum :status, STATUS.index_by(&:itself), validate: true

    validates :modulo, presence: true, uniqueness: { scope: :user_id }
    validate :modulo_no_catalogo

    after_commit { Core::Autorizacao.esquecer(user_id) }

    private

    def modulo_no_catalogo
      errors.add(:modulo, :inclusion) if modulo.present? && !Core::Catalogo.modulo?(modulo)
    end
  end
end
