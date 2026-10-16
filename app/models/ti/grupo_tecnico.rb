module Ti
  # Grupo técnico: equipe que tria e atende um conjunto de solicitações (ex.: REDES, SISTEMAS).
  # Triadores e técnicos só pegam chamados das solicitações dos seus grupos.
  class GrupoTecnico < ApplicationRecord
    include ItemDeCatalogo

    self.table_name = "ti_grupos_tecnicos"

    has_many :vinculos_de_membro, class_name: "Ti::MembroGrupo", foreign_key: :grupo_tecnico_id, inverse_of: :grupo_tecnico, dependent: :destroy
    has_many :membros, through: :vinculos_de_membro, source: :user
    has_many :vinculos_de_problema, class_name: "Ti::ProblemaGrupo", foreign_key: :grupo_tecnico_id, inverse_of: :grupo_tecnico, dependent: :destroy
    has_many :problemas, through: :vinculos_de_problema, source: :problema
  end
end
