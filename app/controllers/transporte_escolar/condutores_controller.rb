# app/controllers/transporte_escolar/condutores_controller.rb

class TransporteEscolar::CondutoresController < ApplicationController
  before_action :verify_permission 
  before_action :set_condutor, only: %i[ show edit update destroy ]
  before_action :load_municipios, only: %i[ new edit create update ]
  before_action :load_tipos, only: %i[ new edit create update ]

  def index
    @condutores = TransporteEscolar::Condutor.all
  end

  def show
  end

  def new
    @condutor = TransporteEscolar::Condutor.new
  end

  def edit
  end

  def create
    @condutor = TransporteEscolar::Condutor.new(condutor_params)

    respond_to do |format|
      if @condutor.save
        flash[:success] = "Condutor criado."
        format.json { render :show, status: :created, location: @condutor }
        format.js { render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @condutor.errors, status: :unprocessable_entity }
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @condutor.update(condutor_params)
        flash[:success] = "Condutor atualizado."
        format.json { render :show, status: :ok, location: @condutor }
        format.js { render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @condutor.errors, status: :unprocessable_entity }
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @condutor.destroy
      flash[:success] = "Condutor excluído"
    else
      flash[:error] = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to transporte_escolar_condutores_url }
      format.json { head :no_content }
    end
  end

  private
    def set_condutor
      @condutor = TransporteEscolar::Condutor.find(params[:id])
    end

    def condutor_params
      params.require(:transporte_escolar_condutor).permit(:nome, :cpf, :tipo, :permissao, :vencimento, :municipio_id, :bairro, :logradouro, :numero, :cep)
    end

    def verify_permission
      if !current_user.has_role? :ges_tp_es and !current_user.has_role? :tec_tp_es and !current_user.has_role? :master
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_municipios
      @municipios = TransporteEscolar::Municipio.order(nome: :asc).all.map{ |m| [m.nome_tipo, m.id] }
    end

    def load_tipos
      @tipos = TransporteEscolar::Condutor.tipos.keys
    end
end
