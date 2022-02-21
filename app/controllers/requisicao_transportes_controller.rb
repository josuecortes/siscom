class RequisicaoTransportesController < ApplicationController
  before_action :set_requisicao_transporte, only: %i[ show edit update destroy ]

  # GET /requisicao_transportes or /requisicao_transportes.json
  def index
    @requisicao_transportes = RequisicaoTransporte.all
  end

  # GET /requisicao_transportes/1 or /requisicao_transportes/1.json
  def show
  end

  # GET /requisicao_transportes/new
  def new
    @requisicao_transporte = RequisicaoTransporte.new
  end

  # GET /requisicao_transportes/1/edit
  def edit
  end

  # POST /requisicao_transportes or /requisicao_transportes.json
  def create
    @requisicao_transporte = RequisicaoTransporte.new(requisicao_transporte_params)

    respond_to do |format|
      if @requisicao_transporte.save
        format.html { redirect_to @requisicao_transporte, notice: "Requisicao transporte was successfully created." }
        format.json { render :show, status: :created, location: @requisicao_transporte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @requisicao_transporte.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requisicao_transportes/1 or /requisicao_transportes/1.json
  def update
    respond_to do |format|
      if @requisicao_transporte.update(requisicao_transporte_params)
        format.html { redirect_to @requisicao_transporte, notice: "Requisicao transporte was successfully updated." }
        format.json { render :show, status: :ok, location: @requisicao_transporte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @requisicao_transporte.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /requisicao_transportes/1 or /requisicao_transportes/1.json
  def destroy
    @requisicao_transporte.destroy
    respond_to do |format|
      format.html { redirect_to requisicao_transportes_url, notice: "Requisicao transporte was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_transporte
      @requisicao_transporte = RequisicaoTransporte.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def requisicao_transporte_params
      params.require(:requisicao_transporte).permit(:status, :user_id, :departamento_id, :tipo, :documento_viagem, :data_hora_ida, :data_hora_retorno, :motivo)
    end
end
