class TipoProblemaTisController < ApplicationController
  before_action :set_tipo_problema_ti, only: %i[ show edit update destroy ]

  # GET /tipo_problema_tis or /tipo_problema_tis.json
  def index
    @tipo_problema_tis = TipoProblemaTi.all
  end

  # GET /tipo_problema_tis/1 or /tipo_problema_tis/1.json
  def show
  end

  # GET /tipo_problema_tis/new
  def new
    @tipo_problema_ti = TipoProblemaTi.new
  end

  # GET /tipo_problema_tis/1/edit
  def edit
  end

  # POST /tipo_problema_tis or /tipo_problema_tis.json
  def create
    @tipo_problema_ti = TipoProblemaTi.new(tipo_problema_ti_params)

    respond_to do |format|
      if @tipo_problema_ti.save
        format.html { redirect_to @tipo_problema_ti, notice: "Tipo problema ti was successfully created." }
        format.json { render :show, status: :created, location: @tipo_problema_ti }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tipo_problema_ti.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tipo_problema_tis/1 or /tipo_problema_tis/1.json
  def update
    respond_to do |format|
      if @tipo_problema_ti.update(tipo_problema_ti_params)
        format.html { redirect_to @tipo_problema_ti, notice: "Tipo problema ti was successfully updated." }
        format.json { render :show, status: :ok, location: @tipo_problema_ti }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tipo_problema_ti.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tipo_problema_tis/1 or /tipo_problema_tis/1.json
  def destroy
    @tipo_problema_ti.destroy
    respond_to do |format|
      format.html { redirect_to tipo_problema_tis_url, notice: "Tipo problema ti was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tipo_problema_ti
      @tipo_problema_ti = TipoProblemaTi.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tipo_problema_ti_params
      params.require(:tipo_problema_ti).permit(:nome, :descricao)
    end
end
