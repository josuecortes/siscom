module Ti
  # Configurações da TI. Existe uma única linha; use Ti::Configuracao.atual.
  class Configuracao < ApplicationRecord
    self.table_name = "ti_configuracoes"

    include SenhaDoPainel

    def self.atual = first || create!
  end
end
