module Transporte
  # Transporte → Operação (porta de transport-requests-module.tsx, visão da operação): todas as
  # solicitações por etapa; o técnico aprova, cancela e reagenda.
  class OperacaoController < BaseController
    POR_PAGINA = 20
    ABAS = { "solicitada" => "Solicitadas", "aprovada" => "Aprovadas", "em_servico" => "Em serviço", "busca" => "Aguardando busca",
             "concluida" => "Concluídas", "cancelada" => "Canceladas" }.freeze

    before_action { pode!(Transporte::Solicitacoes::Reagendar::PERMISSAO) }
    before_action(except: :index) { @solicitacao = Transporte::Solicitacao.find(params[:id]) }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(ABAS.keys) || "solicitada" }
      solicitacoes = Transporte::Solicitacao.all
      solicitacoes = solicitacoes.buscar(@filtros[:q]) if @filtros[:q].present?
      @contagens = solicitacoes.group(:status).count
      @pagy, @solicitacoes = pagy(:offset, solicitacoes.where(status: @filtros[:status]).order(:saida_em, :id).includes(:destinos), limit: POR_PAGINA)
    end

    def show
    end

    def aprovar
      resultado = Transporte::Solicitacoes::Aprovar.call(solicitacao: @solicitacao, ator: current_user)
      opcoes = resultado.sucesso? ? { notice: "Solicitação #{@solicitacao.codigo} aprovada." } : { alert: resultado.mensagem_de_erro }

      redirect_back_or_to transporte_operacao_path(@solicitacao), status: :see_other, **opcoes
    end

    def cancelamento
    end

    def cancelar
      responder Transporte::Solicitacoes::Cancelar.call(solicitacao: @solicitacao, ator: current_user, motivo: params[:motivo]),
                :cancelamento, "Solicitação #{@solicitacao.codigo} cancelada."
    end

    def reagendamento
    end

    def reagendar
      responder Transporte::Solicitacoes::Reagendar.call(solicitacao: @solicitacao, ator: current_user, saida_em: params[:saida_em], retorno_em: params[:retorno_em],
                                                         motivo: params[:motivo]),
                :reagendamento, "Solicitação #{@solicitacao.codigo} reagendada."
    end

    private

    def responder(resultado, tela, aviso)
      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: transporte_operacao_path(@solicitacao))
      else
        @erro = resultado.mensagem_de_erro
        @solicitacao.reload
        render tela, status: :unprocessable_content
      end
    end
  end
end
