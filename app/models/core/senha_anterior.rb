module Core
  # Hashes das senhas anteriores do usuário, para impedir a reutilização.
  class SenhaAnterior < ApplicationRecord
    self.table_name = "core_senhas_anteriores"

    belongs_to :user, class_name: "::User"
  end
end
