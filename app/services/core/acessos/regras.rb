module Core
  module Acessos
    # Quem pode conceder ou revogar um papel:
    # - papéis do Core: só quem tem um papel do Core que o catálogo autoriza a
    #   concedê-lo (hoje, o superadmin);
    # - papéis dos outros módulos: quem tem `core.permissoes.conceder` ou um papel
    #   do próprio módulo autorizado pelo catálogo (bloco `concessao`).
    module Regras
      PERMISSAO_GERAL = "core.permissoes.conceder".freeze

      module_function

      def pode_conceder?(concedente, modulo:, papel:)
        definicao = Core::Catalogo.modulo(modulo)
        return false unless concedente && definicao&.papel?(papel)

        autorizacao = Core::Autorizacao.new(concedente)
        return true if definicao.chave != "core" && autorizacao.pode?(PERMISSAO_GERAL)

        autorizacao.papeis(definicao.chave).any? do |papel_do_concedente|
          definicao.papeis_concediveis_por(papel_do_concedente).include?(papel.to_s)
        end
      end
    end
  end
end
