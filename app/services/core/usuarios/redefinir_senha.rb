module Core
  module Usuarios
    # Redefinição de senha por um administrador: aplica a senha padrão das Configurações (ou, se não
    # houver, uma temporária aleatória), devolvida em `objeto`, obriga a troca no próximo
    # acesso, desbloqueia a conta e derruba as sessões abertas.
    class RedefinirSenha
      PERMISSAO = "core.usuarios.redefinir_senha".freeze

      def self.call(...) = new(...).call

      def initialize(user:, redefinido_por: nil, pelo_sistema: false)
        @user = user
        @redefinido_por = redefinido_por
        @pelo_sistema = pelo_sistema
      end

      def call
        return Core::Resultado.falha("Você não pode redefinir senhas.") unless autorizado?

        temporaria = Core::PoliticaDeSenha.senha_inicial
        @user.transaction do
          @user.update!(password: temporaria, password_confirmation: temporaria, senha_definida_pela_administracao: true, deve_trocar_senha: true)
          @user.unlock_access! if @user.access_locked? || @user.failed_attempts.positive?
          @user.derrubar_sessoes!
          Core::Auditoria::Registrar.call(evento: "core.usuario.senha_redefinida", alvo: @user, ator: @redefinido_por)
        end

        Core::Resultado.sucesso(temporaria)
      rescue ActiveRecord::RecordInvalid => e
        Core::Resultado.falha(e.record)
      end

      private

      def autorizado?
        @pelo_sistema || (@redefinido_por && Core::Autorizacao.new(@redefinido_por).pode?(PERMISSAO))
      end
    end
  end
end
