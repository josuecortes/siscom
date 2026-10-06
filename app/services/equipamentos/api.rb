module Equipamentos
  # Porta de entrada de Equipamentos para os outros módulos. Fora de `Equipamentos`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")
  end
end
