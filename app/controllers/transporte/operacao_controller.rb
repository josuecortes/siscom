module Transporte
  # Transporte → Operação (porta de transport-requests-module.tsx, visão da operação): todas as
  # solicitações por etapa; o técnico aprova, cancela e reagenda.
  class OperacaoController < BaseController
    POR_PAGINA = 20
    ABAS = { "solicitada" => "Solicitadas", "aprovada" => "Aprovadas", "reagendada" => "Reagendadas", "em_servico" => "Em serviço", "busca" => "Aguardando busca",
             "concluida" => "Concluídas", "cancelada" => "Canceladas" }.freeze

    # Ordem da lista: quem sai primeiro, ou quem pediu primeiro.
    ORDENS = { "saida" => [ "Data de saída", { saida_em: :asc, id: :asc } ], "pedido" => [ "Data do pedido", { created_at: :asc, id: :asc } ] }.freeze
    FILTROS = %i[q tipo unidade pedido_de pedido_ate saida_de saida_ate].freeze

    before_action { pode!(Transporte::Solicitacoes::Reagendar::PERMISSAO) }
    before_action(except: :index) { @solicitacao = Transporte::Solicitacao.find(params[:id]) }

    def index
      @filtros = filtros
      solicitacoes = filtrar(Transporte::Solicitacao.all)
      @contagens = solicitacoes.group(:status).count
      # Com algum filtro, as abas viram uma só ("Resultado"), com todas as etapas; a etapa vira coluna.
      solicitacoes = solicitacoes.where(status: @filtros[:status]) unless @filtros[:filtrando]
      @unidades = Transporte::Solicitacao.where.not(unidade_nome: [ nil, "" ]).distinct.order(:unidade_nome).pluck(:unidade_nome)
      @pagy, @solicitacoes = pagy(:offset, solicitacoes.order(ORDENS.fetch(@filtros[:ordem]).last).includes(:destinos), limit: POR_PAGINA)
    end

    def show
      abrir_sobre(transporte_operacao_index_path(status: @solicitacao.status))
    end

    def aprovar
      resultado = Transporte::Solicitacoes::Aprovar.call(solicitacao: @solicitacao, ator: current_user)
      opcoes = resultado.sucesso? ? { notice: "Solicitação #{@solicitacao.codigo} aprovada." } : { alert: resultado.mensagem_de_erro }

      redirect_back_or_to transporte_operacao_index_path, status: :see_other, **opcoes
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
                                                         busca_em: params[:busca_em], motivo: params[:motivo]),
                :reagendamento, (@solicitacao.busca? ? "Busca de #{@solicitacao.codigo} reagendada." : "Reagendamento de #{@solicitacao.codigo} enviado: aguardando a resposta do solicitante.")
    end

    private

    def filtros
      valores = { q: params[:q].to_s.strip, tipo: params[:tipo].presence_in(Transporte::Solicitacao::TIPOS.keys), unidade: params[:unidade].to_s.strip.presence }
      %i[pedido_de pedido_ate saida_de saida_ate].each { |campo| valores[campo] = DataBr.interpretar(params[campo]) }
      valores.merge(status: params[:status].presence_in(ABAS.keys) || "solicitada", ordem: params[:ordem].presence_in(ORDENS.keys) || "saida",
                    filtrando: valores.values.any?(&:present?))
    end

    def filtrar(solicitacoes)
      f = @filtros
      solicitacoes = solicitacoes.buscar(f[:q]) if f[:q].present?
      solicitacoes = solicitacoes.where(tipo: f[:tipo]) if f[:tipo]
      solicitacoes = solicitacoes.where(unidade_nome: f[:unidade]) if f[:unidade]
      solicitacoes = solicitacoes.where(created_at: periodo(f[:pedido_de], f[:pedido_ate])) if f[:pedido_de] || f[:pedido_ate]
      solicitacoes = solicitacoes.where(saida_em: periodo(f[:saida_de], f[:saida_ate])) if f[:saida_de] || f[:saida_ate]
      solicitacoes
    end

    # Dias inteiros, no fuso do sistema.
    def periodo(de, ate) = (de&.in_time_zone&.beginning_of_day)..(ate&.in_time_zone&.end_of_day)

    def responder(resultado, tela, aviso)
      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: transporte_operacao_index_path)
      else
        @erro = resultado.mensagem_de_erro
        @solicitacao.reload
        render tela, status: :unprocessable_content
      end
    end
  end
end
