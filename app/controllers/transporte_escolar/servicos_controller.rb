class TransporteEscolar::ServicosController < ApplicationController
  before_action :verify_permission 
  before_action :set_servico, only: %i[ show edit update destroy ]
  before_action :load_status, only: %i[ edit update ]
  before_action :load_escolas, only: %i[ index edit update search ]
  before_action :load_municipios, only: %i[ index edit update search ]
  before_action :load_transportadores, only: %i[ index edit update search ]
  before_action :load_ano_meses, only: %i[ index edit update search ]
  

  def index
    unless @servicos
      @servicos = TransporteEscolar::Servico.order(created_at: :asc).all
      @ano_mes = Time.now.strftime("%m/%Y")
      @servicos = @servicos.where(ano_mes: @ano_mes)
      @servicos_valor_estimado = @servicos.joins(:contrato).
                                          sum("transporte_escolar_contratos.valor_total")
      @servicos_com_valor = @servicos.joins(:contrato).
                                      where(transporte_escolar_servicos: { status: 'Pago', diarias: 1.. }).
                                      select("transporte_escolar_servicos.*, transporte_escolar_contratos.valor_diaria * transporte_escolar_servicos.diarias as valor_total_diarias")
    end
  end

  def search
    @servicos = TransporteEscolar::Servico.order(created_at: :asc).all
    @ano_mes = params[:ano_mes].present? ? params[:ano_mes] : Time.now.strftime("%m/%Y")
    @servicos = @servicos.where(ano_mes: @ano_mes)

    @municipio = params[:municipio].present? ? params[:municipio] : nil
    @escola = params[:escola].present? ? params[:escola] : nil
    @transportador = params[:transportador].present? ? params[:transportador] : nil

    @servicos = @servicos.joins(contrato: { escola: :municipio }).
                where("transporte_escolar_municipios.id = ?", @municipio) if @municipio.present?
    
    @servicos = @servicos.joins(:contrato).
                where("transporte_escolar_contratos.escola_id = ?", @escola) if @escola.present?

    @servicos = @servicos.joins(:contrato).
                where("transporte_escolar_contratos.transportador_id = ?", @transportador) if @transportador.present?

    
    @servicos_valor_estimado = @servicos.joins(:contrato).
                                          sum("transporte_escolar_contratos.valor_total")
    @servicos_com_valor = @servicos.joins(:contrato).
                                      where(transporte_escolar_servicos: { status: 'Pago', diarias: 1.. }).
                                      select("transporte_escolar_servicos.*, transporte_escolar_contratos.valor_diaria * transporte_escolar_servicos.diarias as valor_total_diarias")

    render :index
  end

  def show
  end
  
  def edit
  end

  def update
    respond_to do |format|
      if @servico.update(servico_params)
        flash[:success] = "Servicço atualizado."
        format.json { render :show, status: :ok, location: @servico }
        format.js { render :update, status: :created  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.json { render json: @servico.errors, status: :unprocessable_entity }
        format.js { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @servico.destroy
    redirect_to transporte_escolar_servicos_url, notice: 'Serviço foi excluído com sucesso.'
  end

  private
    def set_servico
      @servico = TransporteEscolar::Servico.find(params[:id])
    end

    def servico_params
      params.require(:transporte_escolar_servico).permit(:diarias, :status, :nota, :boletim)
    end

    def verify_permission
      if !current_user.has_role? :ges_tp_es and !current_user.has_role? :tec_tp_es and !current_user.has_role? :master
        flash[:info] = "Você não possui as permissões necessárias para acessar!"
        redirect_to home_index_path
      end
    end

    def load_status
      @status = TransporteEscolar::Servico.statuses.keys
    end

    def load_transportadores
      @transportadores = TransporteEscolar::Transportador.order(nome: :asc).all.map{ |t| [t.nome_ou_razao_social, t.id, {:nome_ou_razao_social => t.nome.downcase}] }
    end

    def load_escolas
      @escolas = TransporteEscolar::Escola.order(nome: :asc).all.map{ |e| [e.nome,  e.id, {:nome => e.nome.downcase}] }
    end

    def load_municipios
      @municipios = TransporteEscolar::Municipio.order(nome: :asc).all.map{ |m| [m.nome_tipo, m.id, {:nome => m.nome.downcase}] }
    end

    def load_ano_meses 
      inicio = TransporteEscolar::Contrato.order(inicio: :asc).first&.inicio&.beginning_of_month
      fim = TransporteEscolar::Contrato.order(fim: :asc).last&.fim

      unless inicio
        inicio = Time.now.beginning_of_month
      end
      
      unless fim
        fim = Time.now
      end

      @datas = []

      while inicio <= fim
        @datas << inicio.strftime('%m/%Y')
        inicio = inicio.next_month
      end
    end
end
