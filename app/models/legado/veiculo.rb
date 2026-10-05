module Legado
  # Tabela `veiculos` do siscom antigo (somente leitura).
  class Veiculo < Registro
    self.table_name = "veiculos"
  end
end
