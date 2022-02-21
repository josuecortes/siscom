class PassageirosController < ApplicationController
  before_action :set_passageiro, only: %i[ show edit update destroy ]

  # GET /passageiros or /passageiros.json
  def index
    @passageiros = Passageiro.all
  end

  # GET /passageiros/1 or /passageiros/1.json
  def show
  end

  # GET /passageiros/new
  def new
    @passageiro = Passageiro.new
  end

  # GET /passageiros/1/edit
  def edit
  end

  # POST /passageiros or /passageiros.json
  def create
    @passageiro = Passageiro.new(passageiro_params)

    respond_to do |format|
      if @passageiro.save
        flash[:success] = "Passageiro criado."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /passageiros/1 or /passageiros/1.json
  def update
    respond_to do |format|
      if @passageiro.update(passageiro_params)
        flash[:success] = "Passageiro atualizado."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /passageiros/1 or /passageiros/1.json
  def destroy
    if @passageiro.destroy
      flash[:success] = "Passageiro excluido"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to passageiros_url }
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_passageiro
      @passageiro = Passageiro.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def passageiro_params
      params.require(:passageiro).permit(:nome, :celular, :cpf, :requisicao_transporte_id, :user_id)
    end
end
