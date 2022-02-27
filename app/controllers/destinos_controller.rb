class DestinosController < ApplicationController
  before_action :set_destino, only: %i[ show edit update destroy ]

  # GET /destinos or /destinos.json
  def index
    @destinos = Destino.all
  end

  # GET /destinos/1 or /destinos/1.json
  def show
  end

  # GET /destinos/new
  def new
    @destino = Destino.new
  end

  # GET /destinos/1/edit
  def edit
  end

  # POST /destinos or /destinos.json
  def create
    @destino = Destino.new(destino_params)

    respond_to do |format|
      if @destino.save!
        flash[:success] = "Destino criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /destinos/1 or /destinos/1.json
  def update
    respond_to do |format|
      if @destino.update(destino_params)
        flash[:success] = "Destino atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /destinos/1 or /destinos/1.json
  def destroy
    @destino.destroy
    if @destino.destroy
      flash[:success] = "Destino excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to destinos_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_destino
      @destino = Destino.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def destino_params
      params.require(:destino).permit(:tipo, :descricao, :cep, :numero, :cidade, :bairro, :logradouro, :requisicao_transporte_id, :user_id)
    end
end
