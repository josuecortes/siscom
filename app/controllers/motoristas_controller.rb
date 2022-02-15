class MotoristasController < ApplicationController
  before_action :set_motorista, only: %i[ show edit update destroy ]

  # GET /motoristas or /motoristas.json
  def index
    @motoristas = Motorista.all
  end

  # GET /motoristas/1 or /motoristas/1.json
  def show
  end

  # GET /motoristas/new
  def new
    @motorista = Motorista.new
  end

  # GET /motoristas/1/edit
  def edit
  end

  # POST /motoristas or /motoristas.json
  def create
    @motorista = Motorista.new(motorista_params)
    respond_to do |format|
      if @motorista.save
        flash[:success] = "Motorista criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /motoristas/1 or /motoristas/1.json
  def update
    respond_to do |format|
      if @motorista.update(motorista_params)
        flash[:success] = "Motorista atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /motoristas/1 or /motoristas/1.json
  def destroy
    if @motorista.destroy
      flash[:success] = "Motorista excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to motoristas_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_motorista
      @motorista = Motorista.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def motorista_params
      params.require(:motorista).permit(:nome, :cpf, :data_nascimento, :cnh, :validade_cnh, :celular)
    end
end
