module Ti
  # Porta de entrada da TI para os outros módulos. Fora de `Ti`, só estas funções podem ser usadas.
  module Api
    module_function

    # Entidades da TI que podem virar fonte de referência (nenhuma por enquanto).
    def entidades_publicaveis = {}

    def registros_da_entidade(entidade) = raise(ArgumentError, "entidade desconhecida: #{entidade}")
  end
end
