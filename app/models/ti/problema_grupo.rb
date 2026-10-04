module Ti
  # Grupo técnico que tria e atende uma solicitação.
  class ProblemaGrupo < ApplicationRecord
    self.table_name = "ti_problemas_grupos"

    belongs_to :problema, class_name: "Ti::Problema", inverse_of: :vinculos_de_grupo
    belongs_to :grupo_tecnico, class_name: "Ti::GrupoTecnico", inverse_of: :vinculos_de_problema
  end
end
