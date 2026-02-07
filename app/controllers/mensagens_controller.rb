class MensagensController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:js_create]
  before_action :set_requisicoes, only: [:index, :js_create, :painel]
  before_action :set_conversa, only: [:index, :js_create, :conversa]
  before_action :set_mensagem, only: [:index, :js_create]
  
  def index
  end

  def imagem
    mensagem_id = params[:mensagem_id]
    if mensagem_id
      @mensagem = Mensagem.find(mensagem_id)
    end
    if @mensagem&.imagem&.attached?
      redirect_to rails_blob_path(@mensagem.imagem, disposition: "inline")
    else
      render plain: "Erro ao carregar imagem", status: :not_found
    end
  end

  def show
    render :index
  end

  def js_create

    if @requisicao_ti.status == 'Concluída' or (params[:mensagem].blank? and params[:image].blank?) 
      head :unprocessable_entity
      return
    end
    
    @mensagem.user = current_user
    @mensagem.status = "não lida"
    @mensagem.texto = params[:mensagem] if params[:mensagem]
    @mensagem.imagem = params[:image] if params[:image]

    if @mensagem.save
      destinatario = destinatario_da_conversa
      broadcast_mensagem(destinatario, true) if destinatario && destinatario != current_user
      broadcast_mensagem(current_user, false)
      broadcast_badge(destinatario)
      broadcast_conversa_badge(destinatario)
      broadcast_conversa_badge(current_user)
      broadcast_dropdown(destinatario)
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def painel
    ativas = @requisicoes_ti.select { |r| r.status == "Em atendimento" }
    outras = @requisicoes_ti.reject { |r| r.status == "Em atendimento" }
    @lista_requisicoes = (ativas + outras).first(10)

    if params[:requisicao_ti]
      @requisicao_ti = @lista_requisicoes.find { |r| r.id.to_s == params[:requisicao_ti].to_s }
    end
    @requisicao_ti ||= @lista_requisicoes.first
    @conversa = @requisicao_ti&.mensagens&.order(created_at: :asc)
    render partial: "painel", layout: false
  end

  def conversa
    if @requisicao_ti
      @conversa = @requisicao_ti.mensagens.order(created_at: :asc)
      marcar_conversa_como_lida
      render partial: "conversa", locals: { conversa: @conversa }
    else
      render plain: "", status: :not_found
    end
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
    RequisicaoTi.do_usuario_ou_tecnico(current_user).order(created_at: :desc).each do |requisicao|
      @mensagens_da_requisicao["#{requisicao.id}"] = requisicao.mensagens_nao_lidas(current_user)
      @requisicoes_ti << requisicao
    end
  end

  def set_conversa
    if params[:requisicao_ti] or params[:id]
      id = params[:requisicao_ti]
      unless id
        id = params[:id]
      end
      if @requisicao_ti = RequisicaoTi.do_usuario_ou_tecnico(current_user).pode_enviar_mensagem.find(id)
        @conversa = @requisicao_ti.mensagens.order(created_at: :asc) if @requisicao_ti
        marcar_conversa_como_lida
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

  def marcar_conversa_como_lida
    return unless @requisicao_ti

    @requisicao_ti.mensagens.where("user_id != ? AND status = ?", current_user.id, "não lida").update_all(status: "lida")
    MensagensChannel.broadcast_to(current_user, {
      type: "badge",
      count: current_user.mensagens_nao_lidas
    })
  end

  def destinatario_da_conversa
    if @requisicao_ti.user_id == current_user.id
      @requisicao_ti.tecnico
    else
      @requisicao_ti.user
    end
  end

  def broadcast_badge(user)
    return unless user

    MensagensChannel.broadcast_to(user, {
      type: "badge",
      count: user.mensagens_nao_lidas
    })
  end

  def broadcast_mensagem(user, play_sound)
    return unless user

    html = ApplicationController.render(
      partial: "mensagens/mensagem",
      locals: { mensagem: @mensagem, current_user: user }
    )

    MensagensChannel.broadcast_to(user, {
      type: "mensagem",
      requisicao_id: @requisicao_ti.id,
      html: html,
      playSound: play_sound
    })
  end

  def broadcast_conversa_badge(user)
    return unless user

    MensagensChannel.broadcast_to(user, {
      type: "conversa_badge",
      requisicao_id: @requisicao_ti.id,
      count: @requisicao_ti.mensagens_nao_lidas(user)
    })
  end

  def broadcast_dropdown(user)
    return unless user

    unread_msgs = Mensagem.joins(:requisicao_ti)
      .where(requisicao_tis: { id: RequisicaoTi.do_usuario_ou_tecnico(user).pode_enviar_mensagem.select(:id) })
      .where.not(user_id: user.id)
      .where(status: 'não lida')
      .order(created_at: :desc)
      .limit(5)

    html = ApplicationController.render(
      partial: "mensagens/dropdown_items",
      locals: { unread_msgs: unread_msgs }
    )

    MensagensChannel.broadcast_to(user, {
      type: "dropdown",
      html: html
    })
  end
end
