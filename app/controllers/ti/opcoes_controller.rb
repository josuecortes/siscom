module Ti
  # Opções dos campos de busca dos formulários de chamado, em JSON. As opções vêm da fonte de
  # referência escolhida no campo; só responde para campos de solicitações que o usuário pode abrir.
  class OpcoesController < BaseController
    LIMITE = 50
    MINIMO = 3

    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO) }

    def index
      campo = Ti::CampoProblema.ativo.where(problema_id: Ti::Problema.que_pode_abrir(current_user).select(:id)).find(params[:campo_id])
      raise ActiveRecord::RecordNotFound unless campo.com_fonte?

      termo = params[:q].to_s.squish
      achadas = termo.length >= MINIMO ? Core::Api.opcoes_da_fonte(campo.fonte, termo: termo, limite: LIMITE) : []
      todas = achadas.empty?
      opcoes = todas ? Core::Api.opcoes_da_fonte(campo.fonte, limite: LIMITE) : achadas

      render json: { opcoes: opcoes, todas: todas, restantes: 0 }
    end
  end
end
