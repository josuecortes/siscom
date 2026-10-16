# Módulo Transporte: solicitações de transporte (normal e viagem), passageiros, destinos, serviços,
# motoristas e veículos. Tabelas com prefixo `transporte_`. Outros módulos só usam Transporte::Api.
module Transporte
  def self.table_name_prefix = "transporte_"
end
