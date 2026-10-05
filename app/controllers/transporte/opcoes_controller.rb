module Transporte
  # Opções dos campos de busca (autocomplete) das telas da operação, em JSON.
  class OpcoesController < BaseController
    before_action { pode!(Transporte::Solicitacoes::Reagendar::PERMISSAO) }

    # Unidades do RH, para o filtro "Unidade de quem pediu".
    def unidades
      render json: Rh::Api.opcoes_de_unidades(params[:q])
    end
  end
end
