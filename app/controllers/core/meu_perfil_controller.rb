module Core
  # Minha área → Perfil (porta de my-profile-module.tsx): dados do usuário
  # autenticado e troca da imagem (avatar).
  class MeuPerfilController < ApplicationController
    def show
    end

    def update
      arquivo = params.dig(:user, :avatar)

      if arquivo.blank?
        current_user.errors.add(:avatar, "não foi selecionada")
        render :show, status: :unprocessable_content
      elsif current_user.update(avatar: arquivo)
        redirect_to meu_perfil_path, notice: "Imagem do perfil atualizada.", status: :see_other
      else
        @erros = current_user.errors.full_messages
        current_user.reload
        render :show, status: :unprocessable_content
      end
    end
  end
end
