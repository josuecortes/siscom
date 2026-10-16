module Legado
  # Tabela `mensagens` do siscom antigo (somente leitura).
  class Mensagem < Registro
    self.table_name = "mensagens"
  end
end
