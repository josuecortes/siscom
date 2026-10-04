module Ti
  # Perfil de abertura que pode abrir uma solicitação.
  class ProblemaPerfil < ApplicationRecord
    self.table_name = "ti_problemas_perfis"

    belongs_to :problema, class_name: "Ti::Problema", inverse_of: :vinculos_de_perfil
    belongs_to :perfil_abertura, class_name: "Ti::PerfilAbertura", inverse_of: :vinculos_de_problema
  end
end
