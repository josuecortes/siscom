# app/controllers/transporte_escolar/contratos_controller.rb

class TransporteEscolar::ContratosController < ApplicationController
  before_action :verify_permission
  before_action :set_contrato, only: [:show, :edit, :update, :destroy]
  before_action :load_transportadores, only: %i[ new edit create update ]
  before_action :load_escolas, only: %i[ new edit create update ]
  before_action :load_veiculos, only: %i[ new edit create update ]

  def index
    @contratos = TransporteEscolar::Contrato.order('created_at DESC').all
  end

  def show
  end

  def new
    @contrato = TransporteEscolar::Contrato.new
  end

  def edit
  end

  def create
    @contrato = TransporteEscolar::Contrato.new(contrato_params)
    
    respond_to do |format|
      if @contrato.save!
        flash[:success] = "Contrato criado com sucesso."
        format.js { render :create, status: :created  }
        format.json { render :show, status: :created, location: @contrato }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :new }
        format.json { render json: @contrato.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @contrato.update(contrato_params)
        flash[:success] = "Contrato atualizado com sucesso."
        format.js { render :update, status: :created  }
        format.json { render :show, status: :ok, location: @contrato }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :edit }
        format.json { render json: @contrato.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @contrato.destroy
      flash[:success] = "Contrato excluído com sucesso."
    else
      error_messages = @contrato.errors.full_messages.to_sentence
      flash[:info] = error_messages
      flash[:error] = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to transporte_escolar_contratos_url }
      format.json { head :no_content }
    end
  end

  private
    def set_contrato
      @contrato = TransporteEscolar::Contrato.find(params[:id])
    end

    def contrato_params
      params.require(:transporte_escolar_contrato).permit(:codigo, :rota, :descricao, :inicio, :fim, 
        :valor_total, :valor_diaria, :transportador_id, :escola_id, :veiculo_id)
    end

    def verify_permission
      if !current_user.has_role? :ges_tp_es and !current_user.has_role? :master 
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_transportadores
      @transportadores = TransporteEscolar::Transportador.order(nome: :asc).all.map{ |t| [t.nome_ou_razao_social, t.id, {:nome_ou_razao_social => t.nome.downcase}] }
    end

    def load_escolas
      @escolas = TransporteEscolar::Escola.order(nome: :asc).all.map{ |e| [e.nome,  e.id, {:nome => e.nome.downcase}] }
    end

    def load_veiculos
      @veiculos = TransporteEscolar::Veiculo.order(identificacao: :asc).all.map{ |v| [v.identificacao, v.id, {:identificacao => v.identificacao}] }
    end
end
