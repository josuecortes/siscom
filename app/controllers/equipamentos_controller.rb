class EquipamentosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_equipamento, only: [:show, :edit, :update, :destroy, :transferir, :alterar_status, :remover_de_kit]
  before_action :authorize_equipamento

  def index
    @equipamentos = policy_scope(Equipamento)
    
    # Filtros
    @equipamentos = @equipamentos.por_tipo(params[:tipo]) if params[:tipo].present?
    @equipamentos = @equipamentos.por_status(params[:status]) if params[:status].present?
    @equipamentos = @equipamentos.por_unidade(params[:unidade_id]) if params[:unidade_id].present?
    @equipamentos = @equipamentos.por_tipo_equipamento(params[:tipo_equipamento]) if params[:tipo_equipamento].present?
    @equipamentos = @equipamentos.where("contrato ILIKE ?", "%#{params[:contrato]}%") if params[:contrato].present?
    
    # Busca
    @equipamentos = @equipamentos.buscar(params[:busca]) if params[:busca].present?
    
    # Ordenação
    @equipamentos = @equipamentos.order(created_at: :desc)
    
    # Paginação
    @equipamentos = @equipamentos.page(params[:page]).per(20)
    
    # Para filtros
    @tipos = Equipamento.distinct.pluck(:tipo)
    @status_list = Equipamento.statuses.keys
    @unidades = Unidade.order(:nome)
    @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
  end

  def show
    authorize @equipamento
  end

  def new
    @equipamento = Equipamento.new
    authorize @equipamento
    @unidades = Unidade.order(:nome)
    @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
  end

  def create
    authorize Equipamento
    
    respond_to do |format|
      if equipamento_params[:tipo] == 'kit'
        # Criar kit com múltiplos equipamentos individuais
        begin
          @equipamento = Equipamento.criar_equipamentos_do_kit(equipamento_params, current_user)
          # Contar quantos equipamentos foram criados com o mesmo código de kit
          total_criados = Equipamento.where(codigo_kit: @equipamento.codigo_kit).count
          flash[:success] = "Kit criado com sucesso! #{total_criados} equipamentos individuais foram criados."
          format.js { render :create }
        rescue => e
          @equipamento = Equipamento.new(equipamento_params)
          @unidades = Unidade.order(:nome)
          @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
          flash.now[:error] = "Erro ao criar kit: #{e.message}"
          format.js { render :new }
        end
      else
        # Criar equipamento individual
        @equipamento = Equipamento.new(equipamento_params)
        @equipamento.user = current_user
        
        # Verificar se está tentando incluir em um kit existente
        if equipamento_params[:codigo_kit].present?
          equipamentos_do_kit = Equipamento.where(codigo_kit: equipamento_params[:codigo_kit], tipo: 'individual')
          
          if equipamentos_do_kit.any?
            primeiro_equipamento = equipamentos_do_kit.first
            # Atualizar com informações do kit
            @equipamento.identificacao_kit = primeiro_equipamento.identificacao_kit
            @equipamento.contrato = primeiro_equipamento.contrato
            @equipamento.unidade_id = primeiro_equipamento.unidade_id
          else
            flash.now[:error] = 'Kit não encontrado com o código informado.'
            @unidades = Unidade.order(:nome)
            @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
            format.js { render :new }
            return
          end
        end
        
        if @equipamento.save
          if equipamento_params[:codigo_kit].present?
            flash[:success] = "Equipamento criado e incluído no kit '#{@equipamento.identificacao_kit}' com sucesso."
          else
            flash[:success] = 'Equipamento criado com sucesso.'
          end
          format.js { render :create }
        else
          @unidades = Unidade.order(:nome)
          @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
          flash.now[:error] = 'Ops! Algo deu errado.'
          format.js { render :new }
        end
      end
    end
  end

  def edit
    authorize @equipamento
    @unidades = Unidade.order(:nome)
    @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
  end

  def update
    authorize @equipamento
    respond_to do |format|
      # Verificar se está tentando incluir em um kit
      if equipamento_params[:codigo_kit].present? && equipamento_params[:codigo_kit] != @equipamento.codigo_kit
        # Verificar se o kit existe
        equipamentos_do_kit = Equipamento.where(codigo_kit: equipamento_params[:codigo_kit], tipo: 'individual')
        
        if equipamentos_do_kit.any?
          primeiro_equipamento = equipamentos_do_kit.first
          # Atualizar com informações do kit
          params_para_update = equipamento_params.merge(
            identificacao_kit: primeiro_equipamento.identificacao_kit,
            contrato: primeiro_equipamento.contrato,
            unidade_id: primeiro_equipamento.unidade_id
          )
          
          if @equipamento.update(params_para_update)
            flash[:success] = "Equipamento incluído no kit '#{primeiro_equipamento.identificacao_kit}' com sucesso."
            format.js { render :update }
          else
            @unidades = Unidade.order(:nome)
            @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
            flash.now[:error] = 'Ops! Algo deu errado.'
            format.js { render :edit }
          end
        else
          @unidades = Unidade.order(:nome)
          @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
          flash.now[:error] = 'Kit não encontrado com o código informado.'
          format.js { render :edit }
        end
      else
        # Atualização normal
        if @equipamento.update(equipamento_params)
          flash[:success] = 'Equipamento atualizado com sucesso.'
          format.js { render :update }
        else
          @unidades = Unidade.order(:nome)
          @tipos_equipamento = Equipamento::TIPOS_EQUIPAMENTO
          flash.now[:error] = 'Ops! Algo deu errado.'
          format.js { render :edit }
        end
      end
    end
  end

  def destroy
    authorize @equipamento
    if @equipamento.destroy
      flash[:success] = 'Equipamento removido com sucesso.'
    else
      flash[:error] = 'Ops! Algo deu errado.'
    end
    redirect_to equipamentos_url
  end

  def transferir
    authorize @equipamento
    nova_unidade_id = params[:nova_unidade_id]
    
    if @equipamento.transferir_para_unidade(nova_unidade_id, current_user)
      redirect_to @equipamento, notice: 'Equipamento transferido com sucesso.'
    else
      redirect_to @equipamento, alert: 'Erro ao transferir equipamento.'
    end
  end

  def alterar_status
    authorize @equipamento
    novo_status = params[:novo_status]
    
    if @equipamento.alterar_status(novo_status, current_user)
      redirect_to @equipamento, notice: 'Status alterado com sucesso.'
    else
      redirect_to @equipamento, alert: 'Erro ao alterar status.'
    end
  end

  def buscar
    authorize Equipamento
    termo = params[:termo]
    @equipamentos = policy_scope(Equipamento).buscar(termo).limit(10)
    
    respond_to do |format|
      format.json { render json: @equipamentos.map { |e| { id: e.id, nome: e.nome_completo } } }
    end
  end

  def relatorio
    authorize Equipamento
    @equipamentos = policy_scope(Equipamento)
    
    # Filtros para relatório
    @equipamentos = @equipamentos.por_tipo(params[:tipo]) if params[:tipo].present?
    @equipamentos = @equipamentos.por_status(params[:status]) if params[:status].present?
    @equipamentos = @equipamentos.por_unidade(params[:unidade_id]) if params[:unidade_id].present?
    @equipamentos = @equipamentos.por_tipo_equipamento(params[:tipo_equipamento]) if params[:tipo_equipamento].present?
    @equipamentos = @equipamentos.where("contrato ILIKE ?", "%#{params[:contrato]}%") if params[:contrato].present?
    
    # Busca
    @equipamentos = @equipamentos.buscar(params[:busca]) if params[:busca].present?
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "relatorio_equipamentos_#{Date.current.strftime('%Y%m%d')}",
               template: "equipamentos/relatorio",
               layout: "pdf"
      end
    end
  end

  def verificar_kit
    authorize Equipamento
    codigo_kit = params[:codigo_kit]
    
    if codigo_kit.present?
      equipamentos_do_kit = Equipamento.where(codigo_kit: codigo_kit, tipo: 'individual')
      
      if equipamentos_do_kit.any?
        primeiro_equipamento = equipamentos_do_kit.first
        render json: {
          encontrado: true,
          nome_kit: primeiro_equipamento.identificacao_kit,
          descricao: primeiro_equipamento.descricao,
          unidade: primeiro_equipamento.unidade.sigla_nome,
          total_equipamentos: equipamentos_do_kit.count
        }
      else
        render json: { encontrado: false }
      end
    else
      render json: { encontrado: false }
    end
  end

  def exportar_excel
    authorize Equipamento
    
    # Aplicar os mesmos filtros do index
    @equipamentos = policy_scope(Equipamento)
    
    # Filtros
    @equipamentos = @equipamentos.por_tipo(params[:tipo]) if params[:tipo].present?
    @equipamentos = @equipamentos.por_status(params[:status]) if params[:status].present?
    @equipamentos = @equipamentos.por_unidade(params[:unidade_id]) if params[:unidade_id].present?
    @equipamentos = @equipamentos.por_tipo_equipamento(params[:tipo_equipamento]) if params[:tipo_equipamento].present?
    @equipamentos = @equipamentos.where("contrato ILIKE ?", "%#{params[:contrato]}%") if params[:contrato].present?
    
    # Busca
    @equipamentos = @equipamentos.buscar(params[:busca]) if params[:busca].present?
    
    # Ordenação
    @equipamentos = @equipamentos.order(:codigo_kit, :identificacao_kit, :tipo_equipamento, :marca, :modelo)
    
    # Incluir associações necessárias
    @equipamentos = @equipamentos.includes(:unidade, :user)
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=equipamentos_#{Date.current.strftime('%Y%m%d_%H%M%S')}.xlsx"
        render xlsx: 'exportar_excel', filename: "equipamentos_#{Date.current.strftime('%Y%m%d_%H%M%S')}"
      end
    end
  end

  def remover_de_kit
    authorize @equipamento
    
    respond_to do |format|
      if @equipamento.pertence_a_kit?
        codigo_kit_anterior = @equipamento.codigo_kit
        nome_kit_anterior = @equipamento.identificacao_kit
        
        if @equipamento.update(codigo_kit: nil, identificacao_kit: nil)
          format.html do
            flash[:success] = "Equipamento removido do kit '#{nome_kit_anterior}' com sucesso."
            redirect_to equipamentos_path
          end
          format.json do
            render json: { 
              success: true, 
              message: "Equipamento removido do kit '#{nome_kit_anterior}' com sucesso.",
              redirect_url: equipamentos_path
            }
          end
        else
          format.html do
            flash[:error] = "Erro ao remover equipamento do kit."
            redirect_to edit_equipamento_path(@equipamento)
          end
          format.json do
            render json: { 
              success: false, 
              error: "Erro ao remover equipamento do kit." 
            }, status: :unprocessable_entity
          end
        end
      else
        format.html do
          flash[:error] = "Este equipamento não pertence a nenhum kit."
          redirect_to edit_equipamento_path(@equipamento)
        end
        format.json do
          render json: { 
            success: false, 
            error: "Este equipamento não pertence a nenhum kit." 
          }, status: :unprocessable_entity
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html do
        flash[:error] = "Equipamento não encontrado."
        redirect_to equipamentos_path
      end
      format.json do
        render json: { 
          success: false, 
          error: "Equipamento não encontrado." 
        }, status: :not_found
      end
    end
  end

  private

  def authorize_equipamento
    unless current_user.has_role?(:tec_serv_ti)
      redirect_to root_path, alert: 'Você não tem permissão para acessar esta área.'
    end
  end

  def set_equipamento
    @equipamento = Equipamento.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Equipamento não encontrado."
    redirect_to equipamentos_path
  end

  def equipamento_params
    params.require(:equipamento).permit(:tipo, :tipo_equipamento, :descricao, :marca, :modelo, 
                                       :numero_serial, :numero_patrimonio, :outra_identificacao, 
                                       :identificacao_kit, :codigo_kit, :contrato, :status, :unidade_id, :host, :ip,
                                       :garantia, :historico_movimentacoes,
                                       itens_kit: [:tipo_equipamento, :marca, :modelo, :numero_serial, 
                                                  :numero_patrimonio, :outra_identificacao, :status, 
                                                  :host, :ip, :garantia])
  end
end
