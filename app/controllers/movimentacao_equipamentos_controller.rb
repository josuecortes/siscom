class MovimentacaoEquipamentosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_movimentacao, only: [:show, :receber_equipamento, :cancelar]
  before_action :authorize_movimentacao

  def index
    @movimentacoes = if current_user.has_role?(:tec_serv_ti)
      # Técnicos veem todas as movimentações
      MovimentacaoEquipamento.includes(:unidade_origem, :unidade_destino, :responsavel, :user, :item_movimentacoes)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(20)
    elsif current_user.has_role?(:req_serv_ti)
      # Usuários req_serv_ti veem apenas movimentações onde são responsáveis
      MovimentacaoEquipamento.por_responsavel(current_user.id)
                            .em_andamento
                            .includes(:unidade_origem, :unidade_destino, :responsavel, :user, :item_movimentacoes)
                            .order(created_at: :desc)
                            .page(params[:page])
                            .per(20)
    else
      # Outros usuários não veem nada
      @movimentacoes = MovimentacaoEquipamento.none.page(params[:page])
    end
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
      # Buscar equipamentos da unidade que não estão em movimentações pendentes
      equipamentos_disponiveis = Equipamento.where(unidade_id: unidade_id, tipo: 'individual')
                                           .includes(:unidade)
                                           .order(:tipo_equipamento, :marca, :modelo)
      
      # Filtrar equipamentos que não estão em movimentações em andamento
      # Equipamentos de movimentações canceladas podem ser incluídos em novas movimentações
      @equipamentos = equipamentos_disponiveis.select do |equipamento|
        # Verificar se o equipamento está em alguma movimentação em andamento
        # Equipamentos de movimentações canceladas são liberados automaticamente
        movimentacao_pendente = ItemMovimentacao.joins(:movimentacao_equipamento)
                                               .where(equipamento: equipamento)
                                               .where(status: 'pendente')
                                               .where(movimentacao_equipamentos: { status: 'em_andamento' })
                                               .exists?
        
        !movimentacao_pendente
      end
    else
      @equipamentos = []
    end

    respond_to do |format|
      format.json { 
        render json: @equipamentos.map { |e| 
          { 
            id: e.id, 
            nome: e.nome_completo,
            tipo_equipamento: e.tipo_equipamento,
            marca: e.marca,
            modelo: e.modelo
          } 
        } 
      }
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
end
