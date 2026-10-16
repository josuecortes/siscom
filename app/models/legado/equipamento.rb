module Legado
  # Tabela `equipamentos` do siscom antigo (somente leitura).
  class Equipamento < Registro
    self.table_name = "equipamentos"
  end
end
