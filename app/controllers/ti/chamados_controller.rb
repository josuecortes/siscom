module Ti
  # TI → Meus chamados (porta de helpdesk-tickets-module.tsx): o solicitante abre e acompanha
  # os próprios chamados.
  class ChamadosController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[andamento encerrados]) || "todos" }
      chamados = Ti::Chamado.where(solicitante: current_user).recentes.includes(:problema, :responsavel)
      chamados = chamados.buscar(@filtros[:q]) if @filtros[:q].present?
      chamados = chamados.em_andamento if @filtros[:status] == "andamento"
      chamados = chamados.where.not(status: Ti::Chamado::EM_ANDAMENTO) if @filtros[:status] == "encerrados"
      @pagy, @chamados = pagy(:offset, chamados, limit: POR_PAGINA)
    end

    def show
      @chamado = Ti::Chamado.where(solicitante: current_user).or(Ti::Chamado.where(aberto_por: current_user)).find(params[:id])
      @valores = @chamado.valores.em_ordem.with_attached_arquivos
      @eventos = @chamado.eventos.em_ordem
    end

    # Resposta do solicitante ao pedido de ajuste da operação.
    def resposta
      @chamado = Ti::Chamado.where(solicitante: current_user).find(params[:id])
    end

    def responder
      @chamado = Ti::Chamado.where(solicitante: current_user).find(params[:id])
      resultado = Ti::Chamados::Responder.call(chamado: @chamado, user: current_user, nota: params[:nota])

      if resultado.sucesso?
        concluir_painel(aviso: "Resposta enviada. O chamado #{@chamado.codigo} voltou para a TI.", voltar_para: ti_chamado_path(@chamado))
      else
        @erro = resultado.mensagem_de_erro
        render :resposta, status: :unprocessable_content
      end
    end

    # O painel recarrega ao escolher a solicitação, para mostrar o formulário dela.
    def new
      lotacoes = Rh::Api.lotacoes_ativas(current_user)
      solicitacao = Ti::Problema.que_pode_abrir(current_user).find_by(id: params[:problema_id])
      @formulario = Ti::Chamados::Abrir::Formulario.new(solicitante: current_user, solicitacao: solicitacao, lotacoes: lotacoes, lotacao_id: params[:lotacao_id].presence&.to_i, erros: {})
      carregar_solicitacoes
    end

    def create
      dados = params.fetch(:chamado, {})
      resultado = Ti::Chamados::Abrir.call(user: current_user, problema_id: dados[:problema_id], lotacao_id: dados[:lotacao_id],
                                           respostas: params[:campos])

      if resultado.sucesso?
        concluir_painel(aviso: "Chamado #{resultado.objeto.codigo} aberto com sucesso.", voltar_para: ti_chamados_path)
      else
        @formulario = resultado.objeto
        carregar_solicitacoes
        render :new, status: :unprocessable_content
      end
    end

    private

    def carregar_solicitacoes
      @solicitacoes = Ti::Problema.que_pode_abrir(current_user).ordenados.pluck(:nome, :id)
    end
  end
end
