module Legado
  # Tabela `cargos` do siscom antigo (somente leitura).
  class Cargo < Registro
    self.table_name = "cargos"
  end
end
