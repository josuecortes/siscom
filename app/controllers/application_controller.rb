class ApplicationController < ActionController::Base
  include Pundit

  protect_from_forgery with: :exception
  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized  

  private
    def user_not_authorized
      flash[:info] = "Você não tem permissão para esta ação!! -_-"
      redirect_to home_index_path
    end
end
