module Ti
  # TI → Operação (porta de helpdesk-triage-module.tsx): os chamados que o profissional pode
  # pegar, triar e atender. Não há fila nem distribuição automática: cada um assume o que vai
  # fazer (ou a supervisão atribui).
  class OperacaoController < BaseController
    POR_PAGINA = 20
    # Abas por etapa. "Solicitadas" mostra tudo o que ninguém assumiu (o que a pessoa pode pegar já vem com o botão);
    # as outras mostram só o que é da pessoa, ou de todos quando ela liga "De todos" (aí ela vê, mas só mexe no que é dela).
    ABAS = { "solicitada" => [ "Solicitadas", %w[aberto aguardando_tecnico] ], "em_triagem" => [ "Em triagem", %w[em_triagem] ],
             "em_atendimento" => [ "Em atendimento", %w[em_atendimento] ], "parado" => [ "Parados", %w[aguardando_solicitante impedido] ],
             "concluido" => [ "Concluídos", %w[concluido] ], "finalizado" => [ "Finalizados", %w[finalizado] ], "cancelado" => [ "Cancelados", %w[cancelado] ] }.freeze
    SEM_DONO = "solicitada".freeze

    FEITO = { "assumir" => "assumido por você", "encaminhar" => "encaminhado para atendimento técnico", "devolver" => "ajuste pedido ao solicitante",
              "impedir" => "marcado como impedido", "concluir" => "atendimento concluído", "liberar" => "liberado para outro profissional",
              "atribuir" => "atribuído", "reabrir" => "reaberto", "prioridade" => "prioridade alterada" }.freeze

    before_action { raise Core::AcessoNegado unless Ti::Chamados::Acesso.opera?(current_user) }
    # Mudanças de etapa: na linha da lista ficam atrás de um botão só ("Mudar etapa", como o "Trocar estágio" do seed).
    ETAPAS = %w[encaminhar devolver impedir concluir liberar reabrir].freeze

    before_action :carregar_chamado, only: %i[show etapa acao executar]

    def index
      @filtros = filtros
      visiveis = filtrar(Ti::Chamados::Acesso.visiveis(current_user))
      @contagens = ABAS.to_h { |aba, _| [ aba, da_aba(visiveis, aba).count ] }
      # Com algum filtro, as abas viram uma só ("Resultado"), com tudo o que a pessoa enxerga, de todas as etapas.
      chamados = @filtros[:filtrando] ? visiveis : da_aba(visiveis, @filtros[:status])
      @unidade = Rh::Api.unidade(@filtros[:unidade_id]) if @filtros[:unidade_id]
      @pagy, @chamados = pagy(:offset, chamados.includes(:problema, :responsavel, :triador).order(ordem), limit: POR_PAGINA)
    end

    def show
      @valores = @chamado.valores.em_ordem.with_attached_arquivos
      @eventos = @chamado.eventos.em_ordem
      abrir_sobre(ti_operacao_index_path(status: ABAS.find { |_, (_, status)| status.include?(@chamado.status) }&.first, de: "todos"))
    end

    # Painel que mostra as mudanças de etapa possíveis; cada uma abre o painel da ação.
    def etapa
      @acoes = Ti::Chamados::Operar.disponiveis(@chamado, current_user).select { |acao| ETAPAS.include?(acao.chave) }
      raise Core::AcessoNegado if @acoes.empty?
    end

    # Painel da ação (as que pedem uma anotação, um destinatário ou a prioridade).
    def acao
      @acao = acao_permitida
      @operadores = Ti::Chamados::Acesso.operadores_do(@chamado).pluck(:nome, :id) if @acao.chave == "atribuir"
    end

    def executar
      @acao = acao_permitida
      resultado = Ti::Chamados::Operar.call(chamado: @chamado, acao: @acao.chave, ator: current_user, nota: params[:nota],
                                            alvo: ::User.ativos.find_by(id: params[:alvo_id]), prioridade: params[:prioridade])

      if resultado.sucesso?
        concluir_painel(aviso: "Chamado #{@chamado.codigo}: #{FEITO.fetch(@acao.chave)}.", voltar_para: ti_operacao_index_path)
      elsif @acao.pede_nota
        @erro = resultado.mensagem_de_erro
        @operadores = Ti::Chamados::Acesso.operadores_do(@chamado).pluck(:nome, :id) if @acao.chave == "atribuir"
        render :acao, status: :unprocessable_content
      else
        redirect_back_or_to ti_operacao_index_path, status: :see_other, alert: resultado.mensagem_de_erro
      end
    end

    private

    def carregar_chamado
      @chamado = Ti::Chamados::Acesso.visiveis(current_user).find(params[:id])
    end

    def acao_permitida
      Ti::Chamados::Operar.disponiveis(@chamado, current_user).find { |acao| acao.chave == params[:acao] } || raise(Core::AcessoNegado)
    end

    def filtros
      valores = { q: params[:q].to_s.strip, categoria_id: params[:categoria_id].presence&.to_i, unidade_id: params[:unidade_id].presence&.to_i,
                  aberto_de: DataBr.interpretar(params[:aberto_de]), aberto_ate: DataBr.interpretar(params[:aberto_ate]) }
      valores.merge(status: params[:status].presence_in(ABAS.keys) || SEM_DONO, de: params[:de].presence_in(%w[meus todos]) || "meus",
                    ordem: params[:ordem].presence_in(%w[aberto]), direcao: params[:direcao].presence_in(%w[asc desc]) || "asc",
                    filtrando: valores.values.any?(&:present?))
    end

    def filtrar(chamados)
      f = @filtros
      chamados = chamados.buscar_na_operacao(f[:q]) if f[:q].present?
      chamados = chamados.where(problema_id: Ti::Problema.where(categoria_id: f[:categoria_id]).select(:id)) if f[:categoria_id]
      chamados = chamados.where(rh_unidade_id: f[:unidade_id]) if f[:unidade_id]
      if f[:aberto_de] || f[:aberto_ate]
        chamados = chamados.where(aberto_em: (f[:aberto_de]&.in_time_zone&.beginning_of_day)..(f[:aberto_ate]&.in_time_zone&.end_of_day))
      end
      chamados
    end

    def da_aba(chamados, aba)
      chamados = chamados.where(status: ABAS.fetch(aba).last)
      return chamados.where(responsavel_id: nil) if aba == SEM_DONO
      return chamados if @filtros[:de] == "todos"

      # "Meu": sou o responsável, ou sou o triador e ainda não há responsável.
      chamados.where(responsavel: current_user).or(chamados.where(triador: current_user, responsavel_id: nil))
    end

    # Sem escolha no cabeçalho da coluna: o mais urgente primeiro, depois o mais antigo.
    def ordem
      return { aberto_em: @filtros[:direcao].to_sym, id: :asc } if @filtros[:ordem] == "aberto"

      [ Arel.sql(Ti::Chamado::ORDEM_DE_PRIORIDADE), :aberto_em, :id ]
    end
  end
end
