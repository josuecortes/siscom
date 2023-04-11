class HomeController < ApplicationController
  def index
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

  end
end
