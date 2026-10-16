module Legado
  # Tabela `requisicao_transportes` do siscom antigo (somente leitura).
  class RequisicaoTransporte < Registro
    self.table_name = "requisicao_transportes"
  end
end
