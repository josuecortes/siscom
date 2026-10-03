module Core
  module Acessos
    # Libera ou bloqueia o acesso de um usuário a um módulo inteiro
    # (core_acessos.status). Bloquear vale mesmo para módulos com papel
    # automático; liberar volta à regra normal do catálogo.
    class AlterarModulo
      PERMISSAO = Regras::PERMISSAO_GERAL

      def self.call(...) = new(...).call

      def initialize(user:, modulo:, ativo:, alterado_por:)
        @user = user
        @modulo = modulo.to_s
        @ativo = ativo
        @alterado_por = alterado_por
      end

      def call
        return falha("Módulo inexistente no catálogo: #{@modulo}.") unless Core::Catalogo.modulo?(@modulo)
        return falha("Você não pode alterar permissões.") unless Core::Autorizacao.new(@alterado_por).pode?(PERMISSAO)
        return falha("Você não pode bloquear o seu próprio acesso à Administração.") if trancando_a_si_mesmo?
        return falha("Não é possível bloquear o último superadministrador ativo.") if ultimo_superadmin?

        acesso = Core::Acesso.find_or_initialize_by(user: @user, modulo: @modulo)
        acesso.status = @ativo ? "ativo" : "inativo"
        return Core::Resultado.falha(acesso) unless acesso.save

        if acesso.saved_change_to_status?
          Core::Auditoria::Registrar.call(evento: "core.acesso.modulo_#{@ativo ? 'liberado' : 'bloqueado'}", alvo: @user,
                                          ator: @alterado_por, dados: { modulo: @modulo })
        end
        Core::Resultado.sucesso(acesso)
      end

      private

      def trancando_a_si_mesmo?
        !@ativo && @modulo == "core" && @user == @alterado_por
      end

      def ultimo_superadmin?
        return false if @ativo || @modulo != "core"

        superadmins = Core::Concessao.ativo.where(modulo: "core", papel: "superadmin")
        return false unless superadmins.exists?(user_id: @user.id)

        superadmins.where.not(user_id: @user.id).joins(:user).merge(::User.ativos)
                   .joins(:acesso).merge(Core::Acesso.ativo).none?
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem)
    end
  end
end
