module Legado
  # Tabela `motoristas` do siscom antigo (somente leitura).
  class Motorista < Registro
    self.table_name = "motoristas"
  end
end
