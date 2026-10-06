module Legado
  # Tabela `item_movimentacoes` do siscom antigo (somente leitura).
  class ItemMovimentacao < Registro
    self.table_name = "item_movimentacoes"
  end
end
