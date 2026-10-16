module Transporte
  # Transporte → Operação (porta de transport-requests-module.tsx, visão da operação): todas as
  # solicitações por etapa; o técnico aprova, cancela e reagenda.
  class OperacaoController < BaseController
    POR_PAGINA = 20
    ABAS = { "solicitada" => "Solicitadas", "aprovada" => "Aprovadas", "reagendada" => "Reagendadas", "em_servico" => "Em serviço", "busca" => "Aguardando busca",
             "concluida" => "Concluídas", "cancelada" => "Canceladas" }.freeze

    # Ordem da lista, escolhida no cabeçalho das colunas de data: quem sai primeiro, ou quem pediu primeiro.
    ORDENS = { "saida" => "saida_em", "pedido" => "created_at" }.freeze
    FILTROS = %i[q tipo unidade_id pedido_de pedido_ate saida_de saida_ate].freeze

    # Entram a operação e o motorista; aprovar, cancelar e reagendar são só da operação.
    before_action { raise Core::AcessoNegado unless Transporte::Operacao.opera?(current_user) || Transporte::Operacao.dirige?(current_user) }
    before_action(except: %i[index show]) { pode!(Transporte::Operacao::OPERAR) }
    before_action(except: :index) { @solicitacao = Transporte::Operacao.visiveis(current_user).find(params[:id]) }

    def index
      @filtros = filtros
      @opera = Transporte::Operacao.opera?(current_user)
      @abas = @opera ? ABAS : ABAS.slice(*Transporte::Operacao::ABAS_DO_MOTORISTA)
      @filtros[:status] = @abas.keys.first unless @abas.key?(@filtros[:status])
      solicitacoes = filtrar(Transporte::Operacao.visiveis(current_user))
      @contagens = solicitacoes.group(:status).count
      # Com algum filtro, as abas viram uma só ("Resultado"), com todas as etapas; a etapa vira coluna.
      solicitacoes = solicitacoes.where(status: @filtros[:status]) unless @filtros[:filtrando]
      @unidade = Rh::Api.unidade(@filtros[:unidade_id]) if @filtros[:unidade_id]
      @pagy, @solicitacoes = pagy(:offset, solicitacoes.order(ordem).includes(:destinos), limit: POR_PAGINA)
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
      valores = { q: params[:q].to_s.strip, tipo: params[:tipo].presence_in(Transporte::Solicitacao::TIPOS.keys), unidade_id: params[:unidade_id].presence&.to_i }
      %i[pedido_de pedido_ate saida_de saida_ate].each { |campo| valores[campo] = DataBr.interpretar(params[campo]) }
      valores.merge(status: params[:status].presence_in(ABAS.keys) || "solicitada", ordem: params[:ordem].presence_in(ORDENS.keys) || "saida", direcao: params[:direcao].presence_in(%w[asc desc]) || "asc",
                    filtrando: valores.values.any?(&:present?))
    end

    # Na aba "Aguardando busca" a coluna de saída mostra a hora da busca, e é por ela que se ordena.
    def ordem
      coluna = ORDENS.fetch(@filtros[:ordem])
      coluna = "busca_prevista_em" if coluna == "saida_em" && !@filtros[:filtrando] && @filtros[:status] == "busca"
      { coluna => @filtros[:direcao].to_sym, id: :asc }
    end

    def filtrar(solicitacoes)
      f = @filtros
      solicitacoes = solicitacoes.buscar(f[:q]) if f[:q].present?
      solicitacoes = solicitacoes.where(tipo: f[:tipo]) if f[:tipo]
      solicitacoes = solicitacoes.where(rh_unidade_id: f[:unidade_id]) if f[:unidade_id]
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
