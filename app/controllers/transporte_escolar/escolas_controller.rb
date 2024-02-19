class TransporteEscolar::EscolasController < ApplicationController
  before_action :verify_permission 
  before_action :set_escola, only: %i[ show edit update destroy ]
  before_action :load_municipios, only: %i[ new edit create update ]

  def index
    @escolas = TransporteEscolar::Escola.all
  end

  def show
  end

  def new
    @escola = TransporteEscolar::Escola.new
  end

  def edit
  end

  def create
    @escola = TransporteEscolar::Escola.new(escola_params)

    respond_to do |format|
      if @escola.save
        flash[:success] = "Escola criada."
        format.json { render :show, status: :created, location: @escola }
        format.js {render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @escola.errors, status: :unprocessable_entity }
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @escola.update(escola_params)
        flash[:success] = "Escola atualizada."
        format.json { render :show, status: :ok, location: @escola }
        format.js {render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @escola.errors, status: :unprocessable_entity }
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @escola.destroy
      flash[:success] = "Escola excluida"
    else
      flash[:error] = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to escolas_url }
      format.json { head :no_content }
    end
  end

  private
    def set_escola
      @escola = TransporteEscolar::Escola.find(params[:id])
    end

    def escola_params
      params.require(:transporte_escolar_escola).permit(:codigo, :nome, :municipio_id, :bairro, :logradouro, :numero, :cep)
    end

    def verify_permission
      if !current_user.has_role? :ges_tp_es and !current_user.has_role? :tec_tp_es and !current_user.has_role? :master 
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_municipios
      @municipios = TransporteEscolar::Municipio.order(nome: :asc).all.map{ |m| [m.nome_tipo, m.id, {:nome => m.nome.downcase}] }
    end
end
