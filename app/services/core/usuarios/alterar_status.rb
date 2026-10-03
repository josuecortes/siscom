module Core
  module Usuarios
    # Ativa ou desativa um usuário. Desativar derruba as sessões abertas.
    # Ninguém desativa a si mesmo nem o último superadministrador ativo.
    class AlterarStatus
      def self.call(...) = new(...).call

      def initialize(user:, ativo:, alterado_por:)
        @user = user
        @ativo = ativo
        @alterado_por = alterado_por
      end

      def call
        return falha("Você não pode ativar ou desativar usuários.") unless autorizado?
        return Core::Resultado.sucesso(@user) if @user.ativo? == @ativo
        return falha("Você não pode desativar o seu próprio usuário.") if !@ativo && @user == @alterado_por
        return falha("Não é possível desativar o último superadministrador ativo.") if !@ativo && ultimo_superadmin?

        @user.transaction do
          @user.update!(status: @ativo)
          @ativo ? @user.unlock_access! : @user.derrubar_sessoes!
        end
        Core::Resultado.sucesso(@user)
      rescue ActiveRecord::RecordInvalid => e
        Core::Resultado.falha(e.record)
      end

      private

      def autorizado?
        Core::Autorizacao.new(@alterado_por).pode?(Criar::PERMISSAO)
      end

      def ultimo_superadmin?
        superadmins = Core::Concessao.ativo.where(modulo: "core", papel: "superadmin")
        return false unless superadmins.exists?(user_id: @user.id)

        superadmins.where.not(user_id: @user.id).joins(:user).merge(::User.ativos)
                   .joins(:acesso).merge(Core::Acesso.ativo).none?
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @user)
    end
  end
end
