class IncidentesController < ApplicationController
  before_action :set_incidente, only: %i[ show edit update destroy finalizar salvar ]

  # GET /incidentes or /incidentes.json
  def index
    @incidentes = Incidente.all
  end

  # GET /incidentes/1 or /incidentes/1.json
  def show
  end

  # GET /incidentes/new
  def new
    @incidente = Incidente.new
  end

  # GET /incidentes/1/edit
  def edit
  end

  # POST /incidentes or /incidentes.json
  def create
    @incidente = Incidente.new(incidente_params)
    puts incidente_params
    puts "-------------------------"
    respond_to do |format|
      if @incidente.save
        flash[:success] = "Incidente criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity } 
      end
    end
  end

  # PATCH/PUT /incidentes/1 or /incidentes/1.json
  def update
    respond_to do |format|
      if @incidente.update(incidente_params)
        flash[:success] = "Incidente atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def finalizar

  end

  def salvar
    respond_to do |format|
      if @incidente.update(incidente_params)
        flash[:success] = "Incidente finalizado."
        format.js {render :salvar, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :finalizar, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /incidentes/1 or /incidentes/1.json
  def destroy
    @incidente.destroy

    respond_to do |format|
      format.html { redirect_to incidentes_url, notice: "Incidente was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_incidente
      @incidente = Incidente.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def incidente_params
      params.require(:incidente).permit(:descricao, :texto_explicativo, :previsao_de_retorno, :data_hora_inicio, :data_hora_fim, :ativo)
    end
end
