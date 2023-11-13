class HomeController < ApplicationController
  def index
    requisicoes_transporte
    requisicoes_ti
  end

  def requisicoes_transporte
    @requisicao_transportes = current_user.requisicao_transportes.where(status: [1, 2, 3]).all
    
    @requisicoes_transporte_abertas = RequisicaoTransporte.where(status: 1).all
    @requisicoes_transporte_em_atendimento = current_user.requisicao_transportes.where(status: 2).all
  
  end

  def requisicoes_ti
    @requisicao_tis = current_user.requisicao_tis.where(status: [1, 2, 3]).all
    
    @requisicoes_ti_abertas = RequisicaoTi.where(status: 1).all
    @requisicoes_ti_em_atendimento = current_user.requisicao_tis.where(status: 2).all

    requisicoes_finalizadas = RequisicaoTi.finalizar_requisicoes(current_user)
    if requisicoes_finalizadas > 0
      flash[:error] = "O sistema finalizou automaticamente #{requisicoes_finalizadas} #{requisicoes_finalizadas > 1 ? 'requisições que estavam concluídas ' : 'requisição que estava concluída ' } à mais de 3 dias."
    end

    requisicoes_a_finalizar = RequisicaoTi.requisicoes_a_finalizar(current_user)
    if requisicoes_a_finalizar > 0
      flash[:info] = "Você possui  #{requisicoes_a_finalizar} #{requisicoes_a_finalizar > 1 ? 'requisições concluídas ' : 'requisição concluída ' }. As requisições finalizam automaticamente após 3 dias."
    end

    RequisicaoTi.atualizar_mensagens_nao_lidas(current_user)
  end
end
