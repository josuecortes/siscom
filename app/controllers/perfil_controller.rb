class PerfilController < ApplicationController
  def index
    @usuario = current_user
  end

  def update
    @usuario = current_user
    if @usuario.update(user_params)
      flash[:success] = 'Usuário atualizado'
      redirect_to perfil_index_path(@usuario) 
    else
      flash.now[:error] = "Opss! Algo deu errado."
      render :index 
    end
  end

  private

  def user_params
    params.require(:user).permit(:nome, :email, :avatar, :departamento_id, :funcao_id)
  end
end
