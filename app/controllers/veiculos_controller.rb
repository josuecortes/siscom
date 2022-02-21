class VeiculosController < ApplicationController
  before_action :set_Veiculo, only: %i[ show edit update destroy ]

  # GET /Veiculos or /Veiculos.json
  def index
    @veiculos = Veiculo.all 
  end

  # GET /Veiculos/1 or /Veiculos/1.json
  def show
  end

  # GET /Veiculos/new
  def new
    @veiculo = Veiculo.new
  end

  # GET /Veiculos/1/edit
  def edit
  end

  # POST /Veiculos or /Veiculos.json
  def create
    @veiculo = Veiculo.new(veiculo_params)
    respond_to do |format|
      if @veiculo.save
        flash[:success] = "Veiculo criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /Veiculos/1 or /Veiculos/1.json
  def update
    respond_to do |format|
      if @veiculo.update(veiculo_params)
        flash[:success] = "Veiculo atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /Veiculos/1 or /Veiculos/1.json
  def destroy
    if @veiculo.destroy
      flash[:success] = "Veiculo excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to veiculos_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_Veiculo
      @veiculo = Veiculo.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def veiculo_params
      params.require(:veiculo).permit(:placa, :marca, :modelo, :combustivel, :capacidade, :carga, :status)
    end
end
