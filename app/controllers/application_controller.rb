class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  include Core::ControleDeAcesso

  before_action :exigir_troca_de_senha, unless: :devise_controller?

  private

  # Senha temporária ou padrão antiga: só a tela de troca fica disponível.
  def exigir_troca_de_senha
    return unless current_user&.deve_trocar_senha?
    return if controller_path == "core/minha_senha"

    redirect_to edit_minha_senha_path, status: :see_other
  end
end
