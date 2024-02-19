# app/controllers/transporte_escolar/veiculos_controller.rb

class TransporteEscolar::VeiculosController < ApplicationController
  before_action :verify_permission
  before_action :set_veiculo, only: %i[show edit update destroy]
  before_action :load_transportadores, only: %i[new edit create update]
  before_action :load_procedencias, only: %i[new edit create update]
  before_action :load_tipos, only: %i[new edit create update]
  before_action :load_capacidade_de_cargas, only: %i[new edit create update]
  before_action :load_condutores, only: %i[new edit create update]


  def index
    @veiculos = TransporteEscolar::Veiculo.all
  end

  def show
  end

  def new
    @veiculo = TransporteEscolar::Veiculo.new
  end

  def edit
  end

  def create
    @veiculo = TransporteEscolar::Veiculo.new(veiculo_params)

    respond_to do |format|
      if @veiculo.save
        flash[:success] = "Veículo criado."
        format.json { render :show, status: :created, location: @veiculo }
        format.js { render :create, status: :created }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @veiculo.errors, status: :unprocessable_entity }
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @veiculo.update(veiculo_params)
        flash[:success] = "Veículo atualizado."
        format.json { render :show, status: :ok, location: @veiculo }
        format.js { render :update, status: :created }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @veiculo.errors, status: :unprocessable_entity }
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @veiculo.destroy
      flash[:success] = "Veículo excluído"
    else
      flash[:error] = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to transporte_escolar_veiculos_url }
      format.json { head :no_content }
    end
  end

  private

    def set_veiculo
      @veiculo = TransporteEscolar::Veiculo.find(params[:id])
    end

    def veiculo_params
      params.require(:transporte_escolar_veiculo).permit(:procedencia, :tipo, :identificacao, :ano, :modelo, :marca, :capacidade_pessoas, :capacidade_carga, :transportador_id, :condutor_id)
    end

    def verify_permission
      if !current_user.has_role?(:ges_tp_es) && !current_user.has_role?(:tec_tp_es) && !current_user.has_role?(:master)
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_transportadores
      @transportadores = TransporteEscolar::Transportador.order(nome: :asc).all.map { |t| [t.nome_ou_razao_social, t.id] }
    end

    def load_procedencias
      @procedencias = TransporteEscolar::Veiculo.procedencia.keys
    end
    
    def load_tipos
      @tipos = TransporteEscolar::Veiculo.tipos.keys
    end

    def load_capacidade_de_cargas
      @capacidade_de_cargas = TransporteEscolar::Veiculo.capacidade_cargas.keys
    end

    def load_condutores
      @condutores = TransporteEscolar::Condutor.order(nome: :asc).all.map { |c| [c.nome, c.id] }
    end
end
