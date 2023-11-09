class Useget::RequisicaoTransportesController < ApplicationController
  before_action :verificar_permissao
  before_action :set_requisicao_transporte, only: %i[ show destroy aprovar negar salvar_negacao ]

  layout "acompanhamento", only: [:acompanhamento]

  # GET /requisicao_transportes or /requisicao_transportes.json
  def index
    params[:status] ? @status = params[:status] : @status = 1
    @requisicao_transportes = RequisicaoTransporte.all
    aprovadas = @requisicao_transportes.com_status(2).count
    aguardando = @requisicao_transportes.com_status(1).count
    em_servico = @requisicao_transportes.com_status(3).count
    canceladas = @requisicao_transportes.com_status(5).count
    negadas = @requisicao_transportes.com_status(4).count
    finalizadas = @requisicao_transportes.com_status(6).count
    @contagem_requisicoes = [aguardando, aprovadas, em_servico, negadas, canceladas, finalizadas]
    @requisicao_transportes = @requisicao_transportes.com_status(@status)
  end

  # GET /requisicao_transportes/1 or /requisicao_transportes/1.json
  def show
  end

  def aprovar
    @requisicao_transporte.status = 'aprovada'
    @requisicao_transporte.data_hora_aprovada = Time.now
    @requisicao_transporte.usuario_aprovou = current_user.nome
    salvar_requisicao  
  end

  def negar
    if @requisicao_transporte.status != 'aguardando'
      flash[:error] = "Opss! Você não pode negar essa requisição."
      @erro_padrao = true
    end
  end

  def salvar_negacao
    respond_to do |format|
      if @requisicao_transporte.update(requisicao_transporte_params)
        flash[:success] = "Requisição negada com sucesso."
        format.js {render :salvar_negacao, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :negar, status: :unprocessable_entity }
      end
    end
  end

  def acompanhamento
    @requisicoes_transporte_abertas = RequisicaoTransporte.where(status: 1).order("created_at ASC").all
    @requisicoes_transporte_aprovadas = RequisicaoTransporte.where(status: 2).order("data_hora_ida ASC").all
    @requisicoes_transporte_em_servico = RequisicaoTransporte.where(status: 3).order("data_hora_em_servico DESC").all
  end

  def refresh_acompanhamento
    @requisicoes_transporte_abertas = RequisicaoTransporte.where(status: 1).order("created_at ASC").all
    @requisicoes_transporte_aprovadas = RequisicaoTransporte.where(status: 2).order("data_hora_ida ASC").all
    @requisicoes_transporte_em_servico = RequisicaoTransporte.where(status: 3).order("data_hora_em_servico DESC").all
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_transporte
      if params[:id]
        @requisicao_transporte = RequisicaoTransporte.find(params[:id])
      elsif params[:requisicao_transporte_id]
        @requisicao_transporte = RequisicaoTransporte.find(params[:requisicao_transporte_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def requisicao_transporte_params
      params.require(:requisicao_transporte).permit(:status, :user_id, :unidade_id, :tipo, :documento_viagem, :data_hora_ida, :data_hora_retorno, 
                                                    :motivo, :dia_requisicao_normal_urgente, :hora_requisicao_normal_urgente,
                                                    :motivo_negada, :data_hora_negada, :usuario_negou, 
                                                    passageiros_attributes: [:id, :nome, :cpf, :user_id, :_destroy],
                                                    destinos_attributes: [:id, :descricao, :cep, :numero, :user_id, :_destroy])
    end

    def verificar_permissao
      unless current_user.has_role? :tec_serv_tp or current_user.has_role? :master
        flash[:error] = "Você não possui permissão para acessar essa area!"
        redirect_to home_index_path
      end
    end

    def salvar_requisicao
      if @requisicao_transporte.save
        flash[:success] = "Requisição atualizada"
      else
        flash[:error] = "Erro ao tentar atualizar requisição"
      end
      redirect_to useget_requisicao_transportes_path
    end
end
