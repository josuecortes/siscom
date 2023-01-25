class Nuinfo::RequisicaoTisController < ApplicationController
  before_action :verificar_permissao
  before_action :set_requisicao_ti, only: %i[ show pegar concluir salvar ]

  layout "acompanhamento", only: [:acompanhamento]

  def index
    params[:status] ? @status = params[:status] : @status = 1
    solicitadas = RequisicaoTi.com_status(1).count
    em_atendimento = RequisicaoTi.do_tecnico(current_user).com_status(2).count
    concluidas = RequisicaoTi.do_tecnico(current_user).com_status(3).count
    canceladas = RequisicaoTi.do_tecnico(current_user).com_status(4).count
    finalizadas = RequisicaoTi.do_tecnico(current_user).com_status(5).count
    @contagem_requisicoes = [solicitadas, em_atendimento, concluidas, canceladas, finalizadas]
    if @status.to_i != 1
      @requisicao_tis = RequisicaoTi.do_tecnico(current_user).com_status(@status.to_i)
    else
      @requisicao_tis = RequisicaoTi.com_status(1)
    end
  end

  def show

  end

  def pegar
    if @requisicao_ti.tecnico_id.blank?
      @requisicao_ti.tecnico = current_user
      @requisicao_ti.status = 2
      if @requisicao_ti.save
        flash[:success] = "Você tornou-se o responsável tecnico pela requisição!"
      else  
        flash[:error] = "Opss! Algo deu errado."
      end
    else
      flash[:error] = "Opss! Algo deu errado."
    end
    redirect_to nuinfo_requisicao_tis_path(status: @requisicao_ti.status)
  end

  def concluir
    unless @requisicao_ti.pode_ser_concluida(current_user)
      flash[:error] = "Opss! Você não pode concluir essa requisição."
      @erro_padrao = true  
    end
  end

  def salvar
    respond_to do |format|
      if @requisicao_ti.update(requisicao_ti_params)
        flash[:success] = "Requisição concluída."
        format.js {render :salvar, status: :ok  }
      else
        flash.now[:error] = "Opss! Algo deu errado."
        format.js { render :concluir, status: :unprocessable_entity }
      end
    end
  end

  def acompanhamento
    @tecnicos = Role.where(name: 'tec_serv_ti').first.users
    @requisicoes_ti_abertas = RequisicaoTi.where(status: 1).all
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_requisicao_ti
      if params[:id]
        @requisicao_ti = RequisicaoTi.find(params[:id])
      elsif params[:requisicao_ti_id]
        @requisicao_ti = RequisicaoTi.find(params[:requisicao_ti_id])
      end
    end

    # Only allow a list of trusted parameters through.
    def requisicao_ti_params
      params.require(:requisicao_ti).permit(:status, :user_id, :unidade_id, :problema_ti_id, :observacoes, :solucao)
    end

    def verificar_permissao
      unless current_user.has_role? :tec_serv_ti or current_user.has_role? :master or current_user.has_role? :admin
        flash[:error] = "Você não possui permissão para acessar essa area!"
        redirect_to home_index_path
      end
    end
end
