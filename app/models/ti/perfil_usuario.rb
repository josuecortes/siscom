module Ti
  # Usuário que tem um perfil de abertura.
  class PerfilUsuario < ApplicationRecord
    self.table_name = "ti_perfis_usuario"

    belongs_to :perfil_abertura, class_name: "Ti::PerfilAbertura", inverse_of: :vinculos_de_usuario
    belongs_to :user
    belongs_to :concedido_por, class_name: "User", optional: true

    validates :user_id, uniqueness: { scope: :perfil_abertura_id }
  end
end
