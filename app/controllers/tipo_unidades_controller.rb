class TipoUnidadesController < ApplicationController
  before_action :set_tipo_unidade, only: %i[ show edit update destroy ]

  # GET /tipo_unidades or /tipo_unidades.json
  def index
    @tipo_unidades = TipoUnidade.all
  end

  # GET /tipo_unidades/1 or /tipo_unidades/1.json
  def show
  end

  # GET /tipo_unidades/new
  def new
    @tipo_unidade = TipoUnidade.new
  end

  # GET /tipo_unidades/1/edit
  def edit
  end

  # POST /tipo_unidades or /tipo_unidades.json
  def create
    @tipo_unidade = TipoUnidade.new(tipo_unidade_params)

    respond_to do |format|
      if @tipo_unidade.save
        format.html { redirect_to tipo_unidade_url(@tipo_unidade), notice: "Tipo unidade was successfully created." }
        format.json { render :show, status: :created, location: @tipo_unidade }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tipo_unidade.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tipo_unidades/1 or /tipo_unidades/1.json
  def update
    respond_to do |format|
      if @tipo_unidade.update(tipo_unidade_params)
        format.html { redirect_to tipo_unidade_url(@tipo_unidade), notice: "Tipo unidade was successfully updated." }
        format.json { render :show, status: :ok, location: @tipo_unidade }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tipo_unidade.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tipo_unidades/1 or /tipo_unidades/1.json
  def destroy
    @tipo_unidade.destroy

    respond_to do |format|
      format.html { redirect_to tipo_unidades_url, notice: "Tipo unidade was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tipo_unidade
      @tipo_unidade = TipoUnidade.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tipo_unidade_params
      params.require(:tipo_unidade).permit(:nome)
    end
end
