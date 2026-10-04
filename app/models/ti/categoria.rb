module Ti
  # Categoria de solicitação (ex.: REDE, HARDWARE, SISTEMAS WEB). Agrupa as solicitações do catálogo.
  class Categoria < ApplicationRecord
    include ItemDeCatalogo

    self.table_name = "ti_categorias"

    has_many :problemas, class_name: "Ti::Problema", foreign_key: :categoria_id, inverse_of: :categoria, dependent: :restrict_with_error
  end
end
