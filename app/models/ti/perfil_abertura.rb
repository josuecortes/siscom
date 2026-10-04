module Ti
  # Perfil de abertura: define quais solicitações um usuário pode abrir (ex.: SERVIDOR DA SEDE,
  # DIRETOR DE ESCOLA). É um conceito da TI; não vem do cargo nem da função do RH.
  class PerfilAbertura < ApplicationRecord
    include ItemDeCatalogo

    self.table_name = "ti_perfis_abertura"

    has_many :vinculos_de_usuario, class_name: "Ti::PerfilUsuario", foreign_key: :perfil_abertura_id, inverse_of: :perfil_abertura, dependent: :destroy
    has_many :usuarios, through: :vinculos_de_usuario, source: :user
  end
end
