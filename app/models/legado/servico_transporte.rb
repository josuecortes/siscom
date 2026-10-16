module Legado
  # Tabela `servico_transportes` do siscom antigo (somente leitura).
  class ServicoTransporte < Registro
    self.table_name = "servico_transportes"
  end
end
