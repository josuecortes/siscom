class MensagensController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :set_requisicoes, only: [:index, :refresh, :create]
  before_action :set_conversa, only: [:index, :refresh, :create]
  before_action :set_mensagem, only: [:index, :refresh, :create]
  
  def index
    
  end

  def create
    @mensagem.user = current_user
    @mensagem.status = "não lida"
    @mensagem.texto = params[:mensagem]
    if @mensagem.save
      return true
    else
      return false
    end
  end

  def refresh
    
  end

  def mensagens_diretas
    pode_chatear = current_user.pode_chatear
    mensagens_nao_lidas = current_user.mensagens_nao_lidas
    respond_to do |format|
      format.json { render json: {pode_chatear: pode_chatear, mensagens_nao_lidas: mensagens_nao_lidas} }
    end
  end

  private
  
  def set_requisicoes
    if current_user.has_role? :tec_serv_ti
      @requisicoes_ti = RequisicaoTi.do_tecnico(current_user).pode_enviar_mensagem.order(created_at: :desc)
    else
      @requisicoes_ti = RequisicaoTi.do_usuario(current_user).pode_enviar_mensagem.order(created_at: :desc)
    end
  end

  def set_conversa
    if params[:requisicao_ti]
      if @requisicao_ti = RequisicaoTi.do_usuario_ou_tecnico(current_user).pode_enviar_mensagem.find(params[:requisicao_ti])
        @conversa = @requisicao_ti.mensagens.order(created_at: :asc) if @requisicao_ti
      end
    end
    @requisicao_ti = nil unless @requisicao_ti
    @conversa = nil unless @conversa
  rescue ActiveRecord::RecordNotFound
    @requisicao_ti = nil 
    @conversa = nil 
  end
  
  def set_mensagem
    if @requisicao_ti
      @mensagem = @requisicao_ti.mensagens.new 
    else
      @mensagem = nil
    end
  end
end
