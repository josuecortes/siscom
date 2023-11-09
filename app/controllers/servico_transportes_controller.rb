class ServicoTransportesController < ApplicationController
  before_action :verificar_permissao
  before_action :set_requisicao_transporte, only: %i[ new ]
  before_action :set_servico_transporte, only: %i[ edit update ]
  
  # GET /requisicao_transportes/1 or /requisicao_transportes/1.json
  def show
  end

  # GET /requisicao_transportes/new
  def new
    @servico_transporte = ServicoTransporte.new
  end

  # GET /requisicao_transportes/1/edit
  def edit    
  end

  # POST /requisicao_transportes or /requisicao_transportes.json
  def create
    @servico_transporte = ServicoTransporte.new(servico_transporte_params)
    @servico_transporte.motorista_id = @servico_transporte.veiculo.motorista_id if @servico_transporte.veiculo_id
    respond_to do |format|
      if @servico_transporte.save!
        @servico_transporte.veiculo.mudar_status('em_servico')
        @servico_transporte.requisicao_transporte.mudar_status('em_servico', current_user.nome)
        flash[:success] = "Servico Criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requisicao_transportes/1 or /requisicao_transportes/1.json
  def update
    respond_to do |format|
      if @servico_transporte.update(servico_transporte_params)
        @servico_transporte.veiculo.mudar_status('patio')
        @servico_transporte.requisicao_transporte.mudar_status('finalizada', current_user.nome)
        flash[:success] = "Operação concluida com sucesso."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /requisicao_transportes/1 or /requisicao_transportes/1.json
  def destroy
    if @requisicao_transporte.status == "aguardando" or @requisicao_transporte.status == "aprovada"
      @requisicao_transporte.status = "cancelada"
      if @requisicao_transporte.save
        flash[:success] = "Requisição Cancelada"
      else
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to requisicao_transportes_url }
      format.json { head :no_content }
    end
  end

  private
    def set_requisicao_transporte
      @requisicao_transporte = RequisicaoTransporte.find(params[:requisicao_transporte_id])
    end

    def set_servico_transporte
      @servico_transporte = ServicoTransporte.find(params[:id])
      @requisicao_transporte = @servico_transporte.requisicao_transporte if @servico_transporte
    end

    def servico_transporte_params
      params.require(:servico_transporte).permit(:status, :requisicao_transporte_id, :veiculo_id, :motorista_id, :km_inicial, :km_final, :observacoes)
    end

    def verificar_permissao
      unless current_user.has_role? :tec_serv_tp or current_user.has_role? :master
        flash[:error] = "Você não possui permissão para acessar essa area!"
        redirect_to home_index_path
      end
    end
end
