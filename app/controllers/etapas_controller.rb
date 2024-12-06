class EtapasController < ApplicationController
  before_action :set_acao
  before_action :set_etapa, only: %i[ show edit update destroy ]
  before_action :load_status, only: %i[ new edit create update ]

  # GET /acoes/:acao_id/etapas or /acoes/:acao_id/etapas.json
  def index
    @etapas = @acao.etapas
  end

  # GET /acoes/:acao_id/etapas/1 or /acoes/:acao_id/etapas/1.json
  def show
  end

  # GET /acoes/:acao_id/etapas/new
  def new
    @etapa = @acao.etapas.build
  end

  # GET /acoes/:acao_id/etapas/1/edit
  def edit
  end

  # POST /acoes/:acao_id/etapas or /acoes/:acao_id/etapas.json
  def create
    @etapa = @acao.etapas.build(etapa_params)

    respond_to do |format|
      if @etapa.save
        format.html { redirect_to acao_etapa_url(@acao, @etapa), notice: "Etapa was successfully created." }
        format.js { render :create }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.js { render :new }
      end
    end
  end

  # PATCH/PUT /acoes/:acao_id/etapas/1 or /acoes/:acao_id/etapas/1.json
  def update
    respond_to do |format|
      if @etapa.update(etapa_params)
        format.html { redirect_to acao_etapa_url(@acao, @etapa), notice: "Etapa was successfully updated." }
        format.js { render :update }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.js { render :edit }
      end
    end
  end

  # DELETE /acoes/:acao_id/etapas/1 or /acoes/:acao_id/etapas/1.json
  def destroy
    if @etapa.destroy
      @erro = false
      @mensagem = "Etapa excluída."
    else
      @erro = true
      @mensagem = "Ops. Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to acao_etapas_url(@acao), notice: "Etapa was successfully destroyed." }
      format.js {}
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_acao
      @acao = Acao.find(params[:acao_id])
    end

    def set_etapa
      @etapa = @acao.etapas.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def etapa_params
      params.require(:etapa).permit(
        :nome, :descricao, :inicio, :termino, :status, :acao_id,
        etapa_users_attributes: [:user_id, :id, :_destroy],
      )
    end

    def load_status
      @status = Etapa.statuses.keys
    end
end
