module Core
  # Porta de entrada do Core para os outros módulos. Fora de `Core`, só estas
  # funções (e a infraestrutura pública listada em spec/support/fronteiras.rb)
  # podem ser usadas; o spec de fronteiras falha se outro módulo tocar em
  # models ou services internos do Core.
  module Api
    module_function

    # Módulos declarados em config/modulos/*.yml.
    def modulos = Catalogo.modulos

    def modulo(chave) = Catalogo.modulo(chave)
  end
end
