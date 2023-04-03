class UnidadesController < ApplicationController
  before_action :set_unidade, only: %i[ show edit update destroy ]
  before_action :load_unidade, only: %i[ new edit update create ]

  # GET /unidades or /unidades.json
  def index
    @unidades = Unidade.all
  end

  # GET /unidades/1 or /unidades/1.json
  def show
  end

  # GET /unidades/new
  def new
    @unidade = Unidade.new
  end

  # GET /unidades/1/edit
  def edit
  end

  # POST /unidades or /unidades.json
  def create
    @unidade = Unidade.new(unidade_params)
    respond_to do |format|
      if @unidade.save
        flash[:success] = "Unidade criada."
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unidades/1 or /unidades/1.json
  def update
    respond_to do |format|
      if @unidade.update(unidade_params)
        flash[:success] = "Unidade atualizada."
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unidades/1 or /unidades/1.json
  def destroy
    if @unidade.destroy
      flash[:success] = "Unidade excluida"
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    respond_to do |format|
      format.html { redirect_to unidades_url }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unidade
      @unidade = Unidade.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def unidade_params
      params.require(:unidade).permit(:nome, :sigla, :tipo_unidade_id)
    end

    def load_unidade
      @tipo_unidades = TipoUnidade.order(nome: :asc).map{ |d| [d.nome, d.id, {:nome => d.nome.downcase}] }
    end
end
