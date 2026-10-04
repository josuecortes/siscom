module Ti
  # Usuário que faz parte de um grupo técnico.
  class MembroGrupo < ApplicationRecord
    self.table_name = "ti_membros_grupo"

    belongs_to :grupo_tecnico, class_name: "Ti::GrupoTecnico", inverse_of: :vinculos_de_membro
    belongs_to :user
    belongs_to :concedido_por, class_name: "User", optional: true

    validates :user_id, uniqueness: { scope: :grupo_tecnico_id }
  end
end
