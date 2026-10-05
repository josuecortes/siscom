module Legado
  # Tabela `passageiros` do siscom antigo (somente leitura).
  class Passageiro < Registro
    self.table_name = "passageiros"
  end
end
