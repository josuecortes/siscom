class FuncoesController < ApplicationController
  before_action :set_funcao, only: %i[ show edit update destroy ]

  # GET /funcoes or /funcoes.json
  def index
    @funcoes = Funcao.all
  end

  def autocomplete
    @funcoes = Funcao.search(params[:term]).order(:nome)
    render json: @funcoes.map { |funcao| { id: funcao.id, value: funcao.nome } }
  end  
  
  # GET /funcoes/1 or /funcoes/1.json
  def show
  end

  # GET /funcoes/new
  def new
    @funcao = Funcao.new
  end

  # GET /funcoes/1/edit
  def edit
  end

  # POST /funcoes or /funcoes.json
  def create
    @funcao = Funcao.new(funcao_params)
    respond_to do |format|
      if @funcao.save
        flash[:success] = "Função criada."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /funcoes/1 or /funcoes/1.json
  def update
    respond_to do |format|
      if @funcao.update(funcao_params)
        flash[:success] = "Função atualizada."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /funcoes/1 or /funcoes/1.json
  def destroy
    if @funcao.destroy
      flash[:success] = "Função excluida"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to funcoes_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_funcao
      @funcao = Funcao.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def funcao_params
      params.require(:funcao).permit(:nome)
    end
end
