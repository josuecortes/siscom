class MensagensController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:js_create, :create_imagem]
  before_action :set_requisicoes, only: [:index, :refresh, :js_create, :create_imagem]
  before_action :set_conversa, only: [:index, :refresh, :js_create, :create_imagem]
  before_action :set_mensagem, only: [:index, :refresh, :js_create, :create_imagem]
  
  def index
    
  end

  def imagem
    @mensagem_id = params[:mensagem_id]
    @requisicao_id = params[:requisicao_id]
  end

  def show
    render :index
  end

  def js_create

    if @requisicao_ti.status == 'Concluída' or (params[:mensagem].blank? and params[:image].blank?) 
      return false
    end
    
    @mensagem.user = current_user
    @mensagem.status = "não lida"
    @mensagem.texto = params[:mensagem] if params[:mensagem]
    @mensagem.imagem = params[:image] if params[:image]

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
    @mensagens_da_requisicao = Hash.new
    @requisicoes_ti = []
    RequisicaoTi.do_usuario_ou_tecnico(current_user).pode_enviar_mensagem.order(created_at: :desc).each do |requisicao|
      @mensagens_da_requisicao["#{requisicao.id}"] = requisicao.mensagens_nao_lidas(current_user)
      @requisicoes_ti << requisicao
    end
    
    # @requisicoes_ti = RequisicaoTi.do_usuario_ou_tecnico(current_user).pode_enviar_mensagem.order(created_at: :desc)
    # if current_user.has_role? :tec_serv_ti
    #   @requisicoes_ti = RequisicaoTi.do_tecnico(current_user).pode_enviar_mensagem.order(created_at: :desc)
    # else
    #   @requisicoes_ti = RequisicaoTi.do_usuario(current_user).pode_enviar_mensagem.order(created_at: :desc)
    # end
  end

  def set_conversa
    if params[:requisicao_ti] or params[:id]
      id = params[:requisicao_ti]
      unless id
        id = params[:id]
      end
      if @requisicao_ti = RequisicaoTi.do_usuario_ou_tecnico(current_user).pode_enviar_mensagem.find(id)
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
