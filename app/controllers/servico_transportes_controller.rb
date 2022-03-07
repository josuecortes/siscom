class ServicoTransportesController < ApplicationController
  before_action :set_requisicao_transporte, only: %i[ new ]
  # before_action :set_requisicao_transporte, only: %i[ show edit update ]
  
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

    respond_to do |format|
      if @servico_transporte.save!
        @servico_transporte.motorista = @servico_transporte.veiculo.motorista
        @servico_transporte.save
        @requisicao_transporte = @servico_transporte.requisicao_transporte
        @requisicao_transporte.status = 'em_servico'
        @requisicao_transporte.save
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
      if @requisicao_transporte.update(requisicao_transporte_params)
        flash[:success] = "Requisição atualizada."
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
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_transporte
      puts "---------------------------------"
      puts params[:requisicao_transporte_id]
      @requisicao_transporte = RequisicaoTransporte.find(params[:requisicao_transporte_id])
    end

    # Only allow a list of trusted parameters through.
    def servico_transporte_params
      params.require(:servico_transporte).permit(:status, :requisicao_transporte_id, :veiculo_id, :motorista_id, :km_inicial, :km_final, :observacoes)
    end
end
