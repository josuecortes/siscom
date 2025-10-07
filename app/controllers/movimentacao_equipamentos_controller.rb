class MovimentacaoEquipamentosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_movimentacao, only: [:show, :receber_equipamento, :cancelar]
  before_action :authorize_movimentacao

  def index
    base_scope = if current_user.has_role?(:tec_serv_ti)
      # Técnicos veem todas as movimentações (exceto iniciais)
      MovimentacaoEquipamento.sem_iniciais
    elsif current_user.has_role?(:req_serv_ti)
      # Usuários req_serv_ti veem apenas movimentações onde são responsáveis e em andamento
      MovimentacaoEquipamento.por_responsavel(current_user.id).em_andamento.sem_iniciais
    else
      MovimentacaoEquipamento.none
    end

    @unidades = Unidade.order(:nome)
    @usuarios = User.order(:nome)

    @movimentacoes = aplicar_filtros(base_scope)
                      .includes(:unidade_origem, :unidade_destino, :responsavel, :user, :item_movimentacoes)
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(20)
  end

  def new
    @movimentacao = MovimentacaoEquipamento.new
    @unidades = Unidade.order(:nome)
    @usuarios = User.joins(:roles).where(roles: { name: 'req_serv_ti' }).order(:nome)
  end

  def create
    @movimentacao = MovimentacaoEquipamento.new(movimentacao_params)
    @movimentacao.user = current_user # Criador da movimentação

    if @movimentacao.save
      # Adicionar equipamentos selecionados
      equipamentos_nao_adicionados = []
      
      if params[:equipamento_ids].present?
        params[:equipamento_ids].each do |equipamento_id|
          equipamento = Equipamento.find(equipamento_id)
          unless @movimentacao.adicionar_equipamento(equipamento)
            equipamentos_nao_adicionados << equipamento.nome_completo
          end
        end
      end

      if equipamentos_nao_adicionados.any?
        flash[:warning] = "Movimentação criada com sucesso! Alguns equipamentos não puderam ser adicionados pois já estão em movimentação: #{equipamentos_nao_adicionados.join(', ')}"
      else
        flash[:success] = 'Movimentação criada com sucesso!'
      end
      
      redirect_to movimentacao_equipamentos_path
    else
      @unidades = Unidade.order(:nome)
      @usuarios = User.joins(:roles).where(roles: { name: 'req_serv_ti' }).order(:nome)
      flash.now[:error] = 'Erro ao criar movimentação.'
      render :new
    end
  end

  def show
    @item_movimentacoes = @movimentacao.item_movimentacoes.includes(:equipamento)
  end

  def receber_equipamento
    equipamento = Equipamento.find(params[:equipamento_id])
    
    if @movimentacao.status == 'em_andamento' && @movimentacao.receber_equipamento(equipamento, current_user)
      flash[:success] = "Equipamento '#{equipamento.nome_completo}' recebido com sucesso!"
    else
      flash[:error] = "Erro ao receber equipamento."
    end

    redirect_to movimentacao_equipamento_path(@movimentacao)
  end

  def cancelar
    if @movimentacao.cancelar_movimentacao(current_user)
      flash[:success] = "Movimentação cancelada com sucesso!"
    else
      if @movimentacao.equipamentos_recebidos_count > 0
        flash[:error] = "Não é possível cancelar uma movimentação que já possui equipamentos recebidos."
      elsif @movimentacao.user != current_user
        flash[:error] = "Apenas o criador da movimentação pode cancelá-la."
      else
        flash[:error] = "Erro ao cancelar movimentação."
      end
    end

    redirect_to movimentacao_equipamentos_path
  end

  def buscar_equipamentos
    unidade_id = params[:unidade_id]
    
    if unidade_id.present?
      # Buscar equipamentos da unidade (todos) e marcar bloqueados se estiverem em movimentação em andamento
      equipamentos_scope = Equipamento.where(unidade_id: unidade_id, tipo: 'individual')
                                       .includes(:unidade)
                                       .order(:tipo_equipamento, :marca, :modelo)

      # itens bloqueados por movimentações em andamento (pegar o mais recente por equipamento)
      itens_bloqueados = ItemMovimentacao
                           .joins(:movimentacao_equipamento)
                           .where(status: 'pendente')
                           .where(movimentacao_equipamentos: { status: 'em_andamento' })
                           .includes(movimentacao_equipamento: [:unidade_destino, :responsavel])

      bloqueado_por_equip = {}
      itens_bloqueados.each do |item|
        atual = bloqueado_por_equip[item.equipamento_id]
        if atual.nil? || (atual.movimentacao_equipamento.created_at < item.movimentacao_equipamento.created_at)
          bloqueado_por_equip[item.equipamento_id] = item
        end
      end

      @equipamentos = equipamentos_scope.map do |e|
        item_bloq = bloqueado_por_equip[e.id]
        bloqueado = item_bloq.present?
        unidade_label = nil
        responsavel_curto = nil
        if bloqueado
          mov = item_bloq.movimentacao_equipamento
          unidade = mov.unidade_destino
          begin
            if unidade&.tipo_unidade&.nome == 'ESCOLA'
              unidade_label = unidade.nome
            else
              unidade_label = unidade.respond_to?(:sigla_nome) ? unidade.sigla_nome : unidade.nome
            end
          rescue
            unidade_label = unidade&.nome
          end
          resp_nome = mov.responsavel&.nome.to_s.strip
          if resp_nome.present?
            partes = resp_nome.split
            responsavel_curto = partes.size > 1 ? "#{partes.first} #{partes.last}" : partes.first
          end
        end

        {
          id: e.id,
          nome: e.respond_to?(:nome_completo) ? e.nome_completo : e.modelo || e.marca || e.id,
          tipo_equipamento: e.tipo_equipamento,
          marca: e.marca,
          modelo: e.modelo,
          numero_serial: e.numero_serial,
          numero_patrimonio: e.numero_patrimonio,
          contrato: e.contrato,
          processo: e.processo,
          bloqueado: bloqueado,
          unidade_destino_label: unidade_label,
          responsavel_curto: responsavel_curto
        }
      end
    else
      @equipamentos = []
    end

    respond_to do |format|
      format.json { render json: @equipamentos }
    end
  end

  def buscar_usuarios_unidade
    unidade_id = params[:unidade_id]
    
    if unidade_id.present?
      @usuarios = User.joins(:roles)
                     .where(unidade_id: unidade_id, roles: { name: 'req_serv_ti' })
                     .order(:nome)
    else
      @usuarios = []
    end

    respond_to do |format|
      format.json { render json: @usuarios.map { |u| { id: u.id, nome: u.nome } } }
    end
  end

  private

  def set_movimentacao
    @movimentacao = MovimentacaoEquipamento.includes(:unidade_origem, :unidade_destino, :responsavel, :user).find(params[:id])
  end

  def authorize_movimentacao
    case action_name
    when 'index'
      # Pode ver se é tec_serv_ti ou se é req_serv_ti
      unless current_user.has_role?(:tec_serv_ti) || current_user.has_role?(:req_serv_ti)
        redirect_to home_index_path, alert: 'Você não tem permissão para acessar esta área.'
      end
    when 'show'
      # Pode ver se é tec_serv_ti ou se é req_serv_ti e é responsável
      unless current_user.has_role?(:tec_serv_ti) || 
             (current_user.has_role?(:req_serv_ti) && 
              MovimentacaoEquipamento.por_responsavel(current_user.id).exists?(id: params[:id]))
        redirect_to home_index_path, alert: 'Você não tem permissão para acessar esta área.'
      end
    when 'new', 'create'
      # Só tec_serv_ti pode criar
      unless current_user.has_role?(:tec_serv_ti)
        redirect_to home_index_path, alert: 'Você não tem permissão para criar movimentações.'
      end
    when 'receber_equipamento'
      # Só o responsável pode receber
      unless current_user.has_role?(:req_serv_ti) && 
             MovimentacaoEquipamento.por_responsavel(current_user.id).exists?(id: params[:id])
        redirect_to home_index_path, alert: 'Você não tem permissão para receber equipamentos.'
      end
    when 'cancelar'
      # Só o criador pode cancelar
      unless current_user.has_role?(:tec_serv_ti) && 
             MovimentacaoEquipamento.where(user: current_user).exists?(id: params[:id])
        redirect_to home_index_path, alert: 'Você não tem permissão para cancelar esta movimentação.'
      end
    end
  end

  def movimentacao_params
    params.require(:movimentacao_equipamento).permit(:unidade_origem_id, :unidade_destino_id, :responsavel_id, :descricao)
  end

  def aplicar_filtros(relation)
    rel = relation

    # Filtro por unidade (origem ou destino)
    if params[:unidade_id].present?
      unidade_id = params[:unidade_id]
      rel = rel.where("unidade_origem_id = :uid OR unidade_destino_id = :uid", uid: unidade_id)
    end

    # Filtro por status
    if params[:status].present?
      rel = rel.where(status: params[:status])
    end

    # Filtro por criador (user_id)
    if params[:user_id].present?
      rel = rel.where(user_id: params[:user_id])
    end

    # Filtro por responsável
    if params[:responsavel_id].present?
      rel = rel.where(responsavel_id: params[:responsavel_id])
    end

    # Pesquisa textual em atributos de equipamentos relacionados
    if params[:q].present?
      termo = "%#{params[:q].strip}%"
      rel = rel.joins(:equipamentos).where(
        "equipamentos.marca ILIKE :t OR equipamentos.modelo ILIKE :t OR equipamentos.tipo ILIKE :t OR equipamentos.tipo_equipamento ILIKE :t OR equipamentos.numero_serial ILIKE :t OR equipamentos.numero_patrimonio ILIKE :t OR equipamentos.outra_identificacao ILIKE :t OR equipamentos.descricao ILIKE :t OR equipamentos.contrato ILIKE :t OR equipamentos.processo ILIKE :t OR equipamentos.host ILIKE :t OR equipamentos.ip ILIKE :t OR equipamentos.codigo_kit ILIKE :t OR equipamentos.identificacao_kit ILIKE :t",
        t: termo
      )
    end

    rel.distinct
  end
end
