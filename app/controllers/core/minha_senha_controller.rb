module Core
  # Minha área → Trocar senha (porta de my-password-module.tsx).
  class MinhaSenhaController < ApplicationController
    def edit
      carregar_historico
    end

    def update
      resultado = Core::Usuarios::TrocarSenha.call(
        user: current_user,
        senha_atual: params.dig(:user, :current_password),
        nova_senha: params.dig(:user, :password),
        confirmacao: params.dig(:user, :password_confirmation)
      )

      if resultado.sucesso?
        bypass_sign_in(current_user) # a senha mudou: mantém só esta sessão
        redirect_to root_path, notice: "Senha alterada com sucesso.", status: :see_other
      else
        carregar_historico
        render :edit, status: :unprocessable_content
      end
    end

    private

    # Trocas e redefinições de senha do próprio usuário (auditoria).
    def carregar_historico
      @historico = Core::RegistroAuditoria.do_alvo(current_user).do_modulo("core")
                                          .do_evento(%w[usuario.senha_alterada usuario.senha_redefinida]).recentes.limit(20)
    end
  end
end
