class ApplicationController < ActionController::Base
  include Pundit

  # protect_from_forgery prepend: true
  protect_from_forgery with: :exception
  
  before_action :authenticate_user!
  before_action :verificar_senha_padrao

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized  

  private
    def user_not_authorized
      flash[:info] = "Você não tem permissão para esta ação!! -_-"
      redirect_to home_index_path
    end

    def verificar_senha_padrao
      if current_user
        if current_user.valid_password?('Seed@123')
          flash[:info] = "Você precisa alterar a sua senha!"
          # redirect_to perfil_alterar_senha_url
        end
      end
    end
end
