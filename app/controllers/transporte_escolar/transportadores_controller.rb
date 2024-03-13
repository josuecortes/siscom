# app/controllers/transporte_escolar/transportadores_controller.rb

class TransporteEscolar::TransportadoresController < ApplicationController
  before_action :verify_permission 
  before_action :set_transportador, only: %i[ show edit update destroy ]
  before_action :load_municipios, only: %i[ new edit create update ]
  before_action :load_tipos, only: %i[ new edit create update ]
  before_action :load_tipos_de_contas, only: %i[ new edit create update ]

  def index
    @transportadores = TransporteEscolar::Transportador.all
  end

  def show
  end

  def new
    @transportador = TransporteEscolar::Transportador.new
  end

  def edit
  end

  def create
    @transportador = TransporteEscolar::Transportador.new(transportador_params)

    respond_to do |format|
      if @transportador.save
        flash[:success] = "Transportador criado."
        format.json { render :show, status: :created, location: @transportador }
        format.js { render :create, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @transportador.errors, status: :unprocessable_entity }
        format.js { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @transportador.update(transportador_params)
        flash[:success] = "Transportador atualizado."
        format.json { render :show, status: :ok, location: @transportador }
        format.js { render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @transportador.errors, status: :unprocessable_entity }
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @transportador.destroy
      flash[:success] = "Transportador excluído"
    else
      flash[:error] = "Opss! Algo deu errado."
    end

    respond_to do |format|
      format.html { redirect_to transporte_escolar_transportadores_url }
      format.json { head :no_content }
    end
  end

  private
    def set_transportador
      @transportador = TransporteEscolar::Transportador.find(params[:id])
    end

    def transportador_params
      params.require(:transporte_escolar_transportador).permit(:tipo, :nome, :cpf, :razao_social, :cnpj, :municipio_id, :bairro, :logradouro,
                     :numero, :cep, :codigo, :banco, :agencia, :tipo_de_conta, :conta,
                     :doc_rg, :doc_cpf, :doc_carteira_maritima, :doc_dpen, :doc_tie, :doc_comprovante_endereco_contrato,
                     :doc_certidao_negativa_estadual, :doc_certidao_negativa_federal, :doc_fotos_atualizadas,
                     :doc_relacao_dos_alunos_por_rota, :doc_comprovante_conta_bancaria, :doc_cnh_categoria_d,
                     :doc_auto_de_trafego, :doc_crlv, :doc_certificado_curso_de_condutor_escolar)
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
      @tipos = TransporteEscolar::Transportador.tipos.keys
    end

    def load_tipos_de_contas
      @tipos_de_contas = TransporteEscolar::Transportador.tipo_de_conta.keys
    end
end
