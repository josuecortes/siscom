class ApplicationController < ActionController::Base
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  include Core::ControleDeAcesso
  include Pagy::Method

  before_action :definir_contexto
  before_action :exigir_troca_de_senha, unless: :devise_controller?

  private

  def definir_contexto
    Core::Contexto.ator = current_user
    Core::Contexto.ip = request.remote_ip
    Core::Contexto.request_id = request.request_id
  end

  # Fim de uma ação feita no painel de formulário: fecha o painel, atualiza a
  # página por baixo (Turbo refresh com morph) e mostra o aviso flutuante.
  def concluir_painel(aviso:, voltar_para:)
    flash[:notice] = aviso
    respond_to do |format|
      format.turbo_stream { render turbo_stream: [ turbo_stream.update("painel", ""), turbo_stream.refresh(request_id: nil) ] }
      format.html { redirect_to voltar_para, status: :see_other }
    end
  end

  # As telas de "ver" abrem sempre no painel, por cima da lista, nunca numa página própria. Quando
  # o endereço é aberto direto (link de notificação, favorito), vai para a lista, que abre o painel.
  # Devolve true quando redirecionou.
  def abrir_sobre(lista)
    return false if turbo_frame_request?

    flash.keep # o aviso de quem mandou para cá aparece na lista
    redirect_to "#{lista}#{lista.include?('?') ? '&' : '?'}painel=#{CGI.escape(request.fullpath)}", status: :see_other
    true
  end

  # Senha temporária ou padrão antiga: só a tela de troca fica disponível.
  def exigir_troca_de_senha
    return unless current_user&.deve_trocar_senha?
    return if controller_path == "core/minha_senha"

    redirect_to edit_minha_senha_path, status: :see_other
  end
end
