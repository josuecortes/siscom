class AcoesController < ApplicationController
  before_action :set_acao, only: %i[ show edit update destroy ]
  before_action :load_status, only: %i[ new edit create update ]

  # GET /acoes or /acoes.json
  def index
    @acoes = current_user.acoes
  end

  # GET /acoes/1 or /acoes/1.json
  def show
  end

  # GET /acoes/new
  def new
    @acao = Acao.new
  end

  # GET /acoes/1/edit
  def edit
  end

  # POST /acoes or /acoes.json
  def create
    @acao = Acao.new(acao_params)

    respond_to do |format|
      if @acao.save
        format.html { redirect_to acao_url(@acao), notice: "Acao was successfully created." }
        format.js {}
      else
        format.html { render :new, status: :unprocessable_entity }
        format.js { render :new }
      end
    end
  end

  # PATCH/PUT /acoes/1 or /acoes/1.json
  def update
    respond_to do |format|
      if @acao.update(acao_params)
        format.html { redirect_to acao_url(@acao), notice: "Acao was successfully updated." }
        format.js { render :update }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.html { render :edit, status: :unprocessable_entity }
        format.js { render :edit }
      end
    end
  end

  # DELETE /acoes/1 or /acoes/1.json
  def destroy
    @acao.destroy

    respond_to do |format|
      format.html { redirect_to acoes_url, notice: "Acao was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_acao
      @acao = current_user.acoes.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def acao_params
      params.require(:acao).permit(:nome, :descricao, :inicio, :fim, :motivacao, :orcamento, :status, :mostrar_no_site, :usuario_id)
    end

    def load_status
      @status = Acao.statuses.keys
    end
end
