module Ti
  # A TI abre um chamado em nome de outra pessoa (porta do "abrir para outro usuário" do Transporte
  # do seed): escolhe a pessoa, a lotação dela e a solicitação entre as dos perfis de abertura dela.
  # A pessoa passa a ser a dona do chamado; fica registrado quem abriu.
  class ChamadosParaOutroController < BaseController
    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO_PARA_OUTRO) }

    def new
      dados = params.fetch(:chamado, {})
      solicitante = ::User.ativos.where.not(id: current_user.id).find_by(id: dados[:solicitante_id])
      montar(solicitante: solicitante, problema_id: params[:problema_id], lotacao_id: params[:lotacao_id])
    end

    def create
      dados = params.fetch(:chamado, {})
      solicitante = ::User.ativos.where.not(id: current_user.id).find_by(id: dados[:solicitante_id])
      resultado = Ti::Chamados::Abrir.call(user: solicitante, aberto_por: current_user, problema_id: dados[:problema_id],
                                           lotacao_id: dados[:lotacao_id], respostas: params[:campos])

      if resultado.sucesso?
        chamado = resultado.objeto
        redirect_to ti_chamado_path(chamado), status: :see_other, notice: "Chamado #{chamado.codigo} aberto em nome de #{solicitante.nome}."
      else
        @formulario = resultado.objeto
        @formulario.lotacoes = Rh::Api.lotacoes_ativas(solicitante) if solicitante && @formulario.lotacoes.blank?
        carregar_solicitacoes(solicitante)
        render :new, status: :unprocessable_content
      end
    end

    private

    def montar(solicitante:, problema_id:, lotacao_id:)
      solicitacao = solicitante && Ti::Problema.que_pode_abrir(solicitante).find_by(id: problema_id)
      @formulario = Ti::Chamados::Abrir::Formulario.new(solicitante: solicitante, solicitacao: solicitacao, lotacao_id: lotacao_id.presence&.to_i,
                                                        lotacoes: (solicitante ? Rh::Api.lotacoes_ativas(solicitante) : []), erros: {})
      carregar_solicitacoes(solicitante)
    end

    def carregar_solicitacoes(solicitante)
      @solicitacoes = solicitante ? Ti::Problema.que_pode_abrir(solicitante).ordenados.pluck(:nome, :id) : []
    end
  end
end
