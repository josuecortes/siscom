module Transporte
  # Porta de entrada do Transporte para os outros módulos. Fora de `Transporte`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades do Transporte que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")
  end
end
