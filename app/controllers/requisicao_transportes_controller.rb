class RequisicaoTransportesController < ApplicationController
  before_action :set_requisicao_transporte, only: %i[ show edit update destroy ]

  # GET /requisicao_transportes or /requisicao_transportes.json
  def index
    params[:status] ? @status = params[:status] : @status = 1
    @requisicao_transportes = RequisicaoTransporte.do_usuario(current_user)
    aprovadas = @requisicao_transportes.com_status(2).count
    aguardando = @requisicao_transportes.com_status(1).count
    em_servico = @requisicao_transportes.com_status(3).count
    canceladas = @requisicao_transportes.com_status(5).count
    negadas = @requisicao_transportes.com_status(4).count
    finalizadas = @requisicao_transportes.com_status(6).count
    @contagem_requisicoes = [aguardando, aprovadas, em_servico, negadas, canceladas, finalizadas]
    @requisicao_transportes = @requisicao_transportes.com_status(@status)
  end

  # GET /requisicao_transportes/1 or /requisicao_transportes/1.json
  def show
  end

  # GET /requisicao_transportes/new
  def new
    @requisicao_transporte = RequisicaoTransporte.new
    @requisicao_transporte.tipo = params[:tipo_solicitacao] if params[:tipo_solicitacao]
    @passageiro = @requisicao_transporte.passageiros.build
    @destino = @requisicao_transporte.destinos.build
  end

  # GET /requisicao_transportes/1/edit
  def edit
  end

  # POST /requisicao_transportes or /requisicao_transportes.json
  def create
    @requisicao_transporte = RequisicaoTransporte.new(requisicao_transporte_params)

    respond_to do |format|
      if @requisicao_transporte.save!
        flash[:success] = "Requisição criada."
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
    if @requisicao_transporte.destroy
      flash[:success] = "Requisição excluida"
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
      @requisicao_transporte = RequisicaoTransporte.do_usuario(current_user).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def requisicao_transporte_params
      params.require(:requisicao_transporte).permit(:status, :user_id, :departamento_id, :tipo, :documento_viagem, :data_hora_ida, :data_hora_retorno, 
                                                    :motivo, :dia_requisicao_normal_urgente, :hora_requisicao_normal_urgente, 
                                                    passageiros_attributes: [:id, :nome, :cpf, :user_id, :_destroy],
                                                    destinos_attributes: [:id, :descricao, :cep, :numero, :user_id, :_destroy])
    end
end
