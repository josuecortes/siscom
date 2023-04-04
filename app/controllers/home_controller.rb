class HomeController < ApplicationController
  def index
    @requisicao_tis = current_user.requisicao_tis.where(status: [1, 2, 3]).all
    @requisicoes_ti_abertas = RequisicaoTi.where(status: 1).all
    @requisicoes_ti_em_atendimento = current_user.requisicao_tis.where(status: 2).all
    
  end
end
