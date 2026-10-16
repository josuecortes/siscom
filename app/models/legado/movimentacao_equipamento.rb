module Legado
  # Tabela `movimentacao_equipamentos` do siscom antigo (somente leitura).
  class MovimentacaoEquipamento < Registro
    self.table_name = "movimentacao_equipamentos"
  end
end
