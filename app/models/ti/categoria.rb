module Ti
  # Categoria de solicitação (ex.: REDE, HARDWARE, SISTEMAS WEB). Agrupa as solicitações do catálogo.
  class Categoria < ApplicationRecord
    include ItemDeCatalogo

    self.table_name = "ti_categorias"
  end
end
