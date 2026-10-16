module Core
  # Quem pode ver e gerenciar usuários (permissões do catálogo do Core).
  # Ninguém edita, redefine a senha ou muda o status de si mesmo por esta tela
  # (isso é feito na Minha área).
  class UsuarioPolicy < PoliticaBase
    def index? = permissao?("core.usuarios.ver")
    def create? = permissao?("core.usuarios.gerenciar")
    def update? = create? && outro?
    def alterar_status? = update?
    def redefinir_senha? = permissao?("core.usuarios.redefinir_senha") && outro?
    def ver_permissoes? = permissao?("core.permissoes.conceder")

    class Scope < Scope
      def resolve
        autorizacao.pode?("core.usuarios.ver") ? scope.all : scope.none
      end
    end

    private

    def outro? = record != user
  end
end
