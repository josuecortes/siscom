class Nuinfo::RequisicaoTisController < ApplicationController
  before_action :verificar_permissao
  before_action :set_requisicao_ti, only: %i[ show pegar concluir salvar trocar_tecnico salvar_troca_tecnico ]

  layout "acompanhamento", only: [:acompanhamento]

  def index
    params[:status] ? @status = params[:status] : @status = 1
    solicitadas = RequisicaoTi.com_status(1).count
    em_atendimento = RequisicaoTi.do_tecnico(current_user).com_status(2).count
    concluidas = RequisicaoTi.do_tecnico(current_user).com_status(3).count
    canceladas = RequisicaoTi.do_tecnico(current_user).com_status(4).count
    finalizadas = RequisicaoTi.do_tecnico(current_user).com_status(5).count
    @contagem_requisicoes = [solicitadas, em_atendimento, concluidas, canceladas, finalizadas]
    if @status.to_i != 1
      @requisicao_tis = RequisicaoTi.do_tecnico(current_user).com_status(@status.to_i)
    else
      @requisicao_tis = RequisicaoTi.com_status(1)
    end
  end

  def show

  end

  def pegar
    if @requisicao_ti.tecnico_id.blank?
      @requisicao_ti.tecnico = current_user
      @requisicao_ti.status = 2
      @requisicao_ti.data_hora_em_atendimento = DateTime.now
      if @requisicao_ti.save
        enviar_mensagem_inicio_atendimento(@requisicao_ti)
        flash[:success] = "Você tornou-se o responsável tecnico pela requisição!"
      else
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    redirect_to nuinfo_requisicao_tis_path(status: @requisicao_ti.status)
  end

  def concluir
    unless @requisicao_ti.pode_ser_concluida(current_user)
      flash[:error] = "Opss! Você não pode concluir essa requisição."
      @erro_padrao = true
    end
  end

  def salvar
    respond_to do |format|
      if @requisicao_ti.update(requisicao_ti_params)
        if @requisicao_ti.saved_change_to_status? && @requisicao_ti.status == "Concluída"
          enviar_mensagem_conclusao(@requisicao_ti)
        end
        flash[:success] = "Requisição concluída."
        format.js {render :salvar, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :concluir, status: :unprocessable_entity }
      end
    end
  end

  def trocar_tecnico

  end

  def salvar_troca_tecnico
    respond_to do |format|
      if @requisicao_ti.update(requisicao_ti_params)
        flash[:success] = "Técnico alterado."
        format.js {render :salvar_troca_tecnico, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :trocar_tecnico, status: :unprocessable_entity }
      end
    end
  end

  def acompanhamento
    @tecnicos = Role.where(name: 'tec_serv_ti').first.users
    @requisicoes_ti_abertas = RequisicaoTi.where(status: 1).all
  end

  def refresh_acompanhamento
    @tecnicos = Role.where(name: 'tec_serv_ti').first.users
    @requisicoes_ti_abertas = RequisicaoTi.where(status: 1).all
  end

  def em_atendimento
    @tecnicos = Role.where(name: 'tec_serv_ti').first.users.order(:nome).pluck(:nome, :id) rescue []
    @problemas = ProblemaTi.order(:nome).pluck(:nome, :id)

    # Padrão: últimos 60 dias apenas no carregamento inicial (sem filtros enviados).
    filter_keys = [:data_inicial, :data_final, :email_abertura, :email_relacionado, :nome_relacionado, :tecnico_id, :problema_ti_id, :status, :tipo_data]
    filters = params.slice(*filter_keys)
    applying_defaults = filters.values.all?(&:blank?)

    if applying_defaults
      @data_inicial = 60.days.ago.beginning_of_day
      @data_final   = Time.current.end_of_day
    else
      @data_inicial = params[:data_inicial].present? ? params[:data_inicial].to_date.beginning_of_day : nil
      @data_final   = params[:data_final].present?   ? params[:data_final].to_date.end_of_day         : nil
    end

    tipo_data = params[:tipo_data].presence || 'abertura'
    field_map = {
      'abertura'    => 'created_at',
      'conclusao'   => 'data_hora_concluida',
      'finalizacao' => 'data_hora_finalizada'
    }
    date_field = field_map[tipo_data] || 'created_at'

    scope = RequisicaoTi.includes(:user, :unidade, :problema_ti, :tecnico)
    if @data_inicial
      scope = scope.where("requisicao_tis.#{date_field} >= ?", @data_inicial)
    end
    if @data_final
      scope = scope.where("requisicao_tis.#{date_field} <= ?", @data_final)
    end
    scope = scope.where(problema_ti_id: params[:problema_ti_id]) if params[:problema_ti_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?

    if params[:email_abertura].present?
      email = "%#{params[:email_abertura].strip}%"
      scope = scope.left_joins(:user).where("users.email ILIKE ? OR requisicao_tis.email ILIKE ?", email, email)
    end

    if params[:email_relacionado].present?
      scope = scope.where("requisicao_tis.email ILIKE ?", "%#{params[:email_relacionado].strip}%")
    end

    if params[:nome_relacionado].present?
      scope = scope.where("requisicao_tis.nome ILIKE ?", "%#{params[:nome_relacionado].strip}%")
    end

    if params[:tecnico_id].present?
      scope = scope.where(tecnico_id: params[:tecnico_id])
    end

    @requisicoes = scope.order(created_at: :desc)
  end

  private

  def enviar_mensagem_inicio_atendimento(requisicao)
    return unless requisicao&.tecnico && requisicao&.user

    texto = mensagem_inicio_texto(requisicao)
    criar_mensagem_automatica(requisicao, texto)
  end

  def enviar_mensagem_conclusao(requisicao)
    return unless requisicao&.tecnico && requisicao&.user

    texto = mensagem_conclusao_texto(requisicao)
    criar_mensagem_automatica(requisicao, texto)
  end

  def mensagem_inicio_texto(requisicao)
    tecnico_nome = requisicao.tecnico&.nome || "técnico"
    "Mensagem automática do sistema: o técnico #{tecnico_nome} iniciou o atendimento do chamado ##{requisicao.id}. Enquanto o chamado estiver em atendimento, você pode conversar com o técnico por aqui. Fique atento, pois o técnico pode enviar mensagens a qualquer momento."
  end

  def mensagem_conclusao_texto(requisicao)
    tecnico_nome = requisicao.tecnico&.nome || "técnico"
    "Mensagem automática do sistema: o técnico #{tecnico_nome} concluiu o chamado ##{requisicao.id}. Este chat agora é apenas para histórico e não permite novas mensagens."
  end

  def criar_mensagem_automatica(requisicao, texto)
    mensagem = requisicao.mensagens.new(
      user: requisicao.tecnico,
      texto: texto,
      status: "não lida"
    )
    return unless mensagem.save

    destinatario = requisicao.user
    broadcast_mensagem(destinatario, mensagem, true)
    broadcast_mensagem(requisicao.tecnico, mensagem, false)
    broadcast_badge(destinatario)
    broadcast_conversa_badge(destinatario, requisicao)
    broadcast_dropdown(destinatario)
  end

  def broadcast_mensagem(user, mensagem, play_sound)
    return unless user

    html = ApplicationController.render(
      partial: "mensagens/mensagem",
      locals: { mensagem: mensagem, current_user: user }
    )

    MensagensChannel.broadcast_to(user, {
      type: "mensagem",
      requisicao_id: mensagem.requisicao_ti_id,
      html: html,
      playSound: play_sound
    })
  end

  def broadcast_badge(user)
    return unless user

    MensagensChannel.broadcast_to(user, {
      type: "badge",
      count: user.mensagens_nao_lidas
    })
  end

  def broadcast_conversa_badge(user, requisicao)
    return unless user

    MensagensChannel.broadcast_to(user, {
      type: "conversa_badge",
      requisicao_id: requisicao.id,
      count: requisicao.mensagens_nao_lidas(user)
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

  def estatisticas
    carregar_estatisticas
  end

  def buscar_estatisticas
    carregar_estatisticas
    render :estatisticas
  end

  def carregar_estatisticas
    @tecnicos = Role.where(name: 'tec_serv_ti').first.users.map{ |u| [u.nome, u.id] }
    @tecnico_id = params[:tecnico_id] if params[:tecnico_id] != 'Todos' and !params[:tecnico_id].blank?
    @tecnico = User.find @tecnico_id if @tecnico_id
    
    if params[:data_inicial]
      @data_inicial = params[:data_inicial].to_time
    else
      @data_inicial = "01/01/2020".to_time
    end
    
    if params[:data_final]
      @data_final = params[:data_final].to_time 
    else
      @data_final = (Time.now + 1.day).beginning_of_day  
    end

    @tipo_problemas = params[:tipo_problemas]

    @requisicoes = RequisicaoTi.order("created_at ASC").all
    @acoes = Acao.order(inicio: :asc, termino: :asc).all

    if @tecnico
      @requisicoes = @requisicoes.do_tecnico(@tecnico_id)
    end
    if @data_inicial
      @requisicoes = @requisicoes.where("requisicao_tis.created_at >= ?", @data_inicial)
      @acoes = @acoes.where("created_at >= ?", @data_inicial)
    end
    if @data_final
      @requisicoes = @requisicoes.where("requisicao_tis.created_at <= ?", @data_final)
      @acoes = @acoes.where("created_at <= ?", @data_final)
    end
    if @tipo_problemas and @tipo_problemas.count >= 1
      @requisicoes = @requisicoes.joins(:problema_ti).where("problema_tis.tipo_problema_ti_id in (?)", @tipo_problemas.map{|tp| tp.to_i}.to_a)
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_ti
      if params[:id]
        @requisicao_ti = RequisicaoTi.find(params[:id])
      elsif params[:requisicao_ti_id]
        @requisicao_ti = RequisicaoTi.find(params[:requisicao_ti_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def requisicao_ti_params
      params.require(:requisicao_ti).permit(:status, :user_id, :unidade_id, :problema_ti_id, :observacoes, :solucao, :data_hora_concluida, :tecnico_id)
    end

    def verificar_permissao
      unless current_user.has_role? :tec_serv_ti or current_user.has_role? :master or current_user.has_role? :admin
        flash[:error] = "Você não possui permissão para acessar essa area!"
        redirect_to home_index_path
      end
    end
end
