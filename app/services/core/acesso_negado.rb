module Core
  # Levantado quando o usuário não tem acesso ao módulo ou a permissão exigida.
  # O ApplicationController responde com 403.
  class AcessoNegado < StandardError
    attr_reader :permissao

    def initialize(permissao = nil)
      @permissao = permissao
      super(permissao ? "sem permissão: #{permissao}" : "acesso negado")
    end
  end
end
