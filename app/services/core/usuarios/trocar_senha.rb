module Core
  module Usuarios
    # Troca de senha pelo próprio usuário: confere a senha atual, aplica a
    # política de senha e libera a troca obrigatória. Como a senha muda, todas
    # as outras sessões do usuário caem (o controller mantém a atual).
    class TrocarSenha
      def self.call(...) = new(...).call

      def initialize(user:, senha_atual:, nova_senha:, confirmacao:)
        @user = user
        @senha_atual = senha_atual.to_s
        @nova_senha = nova_senha.to_s
        @confirmacao = confirmacao.to_s
      end

      def call
        @user.errors.clear
        unless @user.valid_password?(@senha_atual)
          @user.errors.add(:current_password, "não confere")
          return Core::Resultado.falha(@user)
        end

        if @nova_senha.blank?
          @user.errors.add(:password, :blank)
          return Core::Resultado.falha(@user)
        end

        obrigatoria = @user.deve_trocar_senha?
        if @user.update(password: @nova_senha, password_confirmation: @confirmacao, deve_trocar_senha: false)
          Core::Auditoria::Registrar.call(evento: "core.usuario.senha_alterada", alvo: @user, ator: @user, dados: { troca_obrigatoria: obrigatoria })
          return Core::Resultado.sucesso(@user)
        end

        # Não deixa a senha recusada (nem o hash dela) no objeto em memória.
        resultado = Core::Resultado.falha(@user)
        @user.restore_attributes(%w[encrypted_password deve_trocar_senha])
        @user.password = @user.password_confirmation = nil
        resultado
      end
    end
  end
end
