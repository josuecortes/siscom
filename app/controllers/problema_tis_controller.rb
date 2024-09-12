class ProblemaTisController < ApplicationController
  before_action :set_problema_ti, only: %i[ show edit update destroy ]
  before_action :load_problemas, only: %i[ new edit update create ]

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
        flash[:success] = "Problema criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /problema_tis/1 or /problema_tis/1.json
  def update
    respond_to do |format|
      if @problema_ti.update(problema_ti_params)
        flash[:success] = "Problema atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /problema_tis/1 or /problema_tis/1.json
  def destroy
    if @problema_ti.destroy
      flash[:success] = "Problema excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to problema_tis_url }
    end  

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_problema_ti
      @problema_ti = ProblemaTi.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def problema_ti_params
      params.require(:problema_ti).permit(:nome, :descricao, :status, :tipo_problema_ti_id)
    end

    def load_problemas
      @tipo_problemas = TipoProblemaTi.order(nome: :asc).map{ |p| [p.nome, p.id, {:nome => p.nome.downcase}] }
    end
end
