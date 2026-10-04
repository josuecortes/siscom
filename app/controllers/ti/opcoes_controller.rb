module Ti
  # Opções dos campos de busca dos formulários de chamado, em JSON. As opções vêm da fonte de
  # referência escolhida no campo; só responde para campos de solicitações que o usuário pode abrir.
  class OpcoesController < BaseController
    LIMITE = 50
    MINIMO = 3

    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO) }

    # Usuários ativos, para quem abre chamado em nome de outra pessoa.
    def usuarios
      pode!(Ti::Chamados::Abrir::PERMISSAO_PARA_OUTRO)
      termo = params[:q].to_s.squish
      ativos = ::User.ativos.where.not(id: current_user.id).order(:nome, :id)
      achados = termo.length >= MINIMO ? ativos.buscar(termo) : ativos.none
      todas = achados.none?
      escolhidos = todas ? ativos : achados

      render json: { opcoes: escolhidos.limit(LIMITE).map { |user| { valor: user.id, rotulo: user.nome, subtitulo: user.email } },
                     todas: todas, restantes: [ escolhidos.count - LIMITE, 0 ].max }
    end

    # Quem abre em nome de outra pessoa (`solicitante_id`) vê os campos das solicitações dela.
    def index
      campo = Ti::CampoProblema.ativo.where(problema_id: Ti::Problema.que_pode_abrir(dono_do_chamado).select(:id)).find(params[:campo_id])
      raise ActiveRecord::RecordNotFound unless campo.com_fonte?

      termo = params[:q].to_s.squish
      achadas = termo.length >= MINIMO ? Core::Api.opcoes_da_fonte(campo.fonte, termo: termo, limite: LIMITE) : []
      todas = achadas.empty?
      opcoes = todas ? Core::Api.opcoes_da_fonte(campo.fonte, limite: LIMITE) : achadas

      render json: { opcoes: opcoes, todas: todas, restantes: 0 }
    end

    private

    def dono_do_chamado
      return current_user if params[:solicitante_id].blank?

      pode!(Ti::Chamados::Abrir::PERMISSAO_PARA_OUTRO)
      ::User.ativos.find(params[:solicitante_id])
    end
  end
end
