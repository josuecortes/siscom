class ProblemaTisController < ApplicationController
  before_action :set_problema_ti, only: %i[ show edit update destroy ]

  # GET /problema_tis or /problema_tis.json
  def index
    @problema_tis = ProblemaTi.all
  end

  # GET /problema_tis/1 or /problema_tis/1.json
  def show
  end

  # GET /problema_tis/new
  def new
    @problema_ti = ProblemaTi.new
  end

  # GET /problema_tis/1/edit
  def edit
  end

  # POST /problema_tis or /problema_tis.json
  def create
    @problema_ti = ProblemaTi.new(problema_ti_params)

    respond_to do |format|
      if @problema_ti.save
        format.html { redirect_to @problema_ti, notice: "Problema ti was successfully created." }
        format.json { render :show, status: :created, location: @problema_ti }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @problema_ti.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /problema_tis/1 or /problema_tis/1.json
  def update
    respond_to do |format|
      if @problema_ti.update(problema_ti_params)
        format.html { redirect_to @problema_ti, notice: "Problema ti was successfully updated." }
        format.json { render :show, status: :ok, location: @problema_ti }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @problema_ti.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /problema_tis/1 or /problema_tis/1.json
  def destroy
    @problema_ti.destroy
    respond_to do |format|
      format.html { redirect_to problema_tis_url, notice: "Problema ti was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_problema_ti
      @problema_ti = ProblemaTi.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def problema_ti_params
      params.require(:problema_ti).permit(:nome, :descricao, :tipo_problema_ti_id)
    end
end
