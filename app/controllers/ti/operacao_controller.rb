module Ti
  # TI → Operação (porta de helpdesk-triage-module.tsx): os chamados que o profissional pode
  # pegar, triar e atender. Não há fila nem distribuição automática: cada um assume o que vai
  # fazer (ou a supervisão atribui).
  class OperacaoController < BaseController
    POR_PAGINA = 20
    VISOES = { "disponiveis" => "Sem responsável", "meus" => "Comigo", "andamento" => "Todos em andamento", "encerrados" => "Encerrados" }.freeze

    FEITO = { "assumir" => "assumido por você", "encaminhar" => "encaminhado para atendimento técnico", "devolver" => "ajuste pedido ao solicitante",
              "impedir" => "marcado como impedido", "concluir" => "atendimento concluído", "liberar" => "liberado para outro profissional",
              "atribuir" => "atribuído", "reabrir" => "reaberto", "prioridade" => "prioridade alterada" }.freeze

    before_action { raise Core::AcessoNegado unless Ti::Chamados::Acesso.opera?(current_user) }
    # Mudanças de etapa: na linha da lista ficam atrás de um botão só ("Mudar etapa", como o "Trocar estágio" do seed).
    ETAPAS = %w[encaminhar devolver impedir concluir liberar reabrir].freeze

    before_action :carregar_chamado, only: %i[show etapa acao executar]

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(VISOES.keys) || "disponiveis" }
      chamados = filtrar(Ti::Chamados::Acesso.visiveis(current_user), @filtros[:status]).includes(:problema, :responsavel, :triador)
      chamados = chamados.buscar_na_operacao(@filtros[:q]) if @filtros[:q].present?
      @pagy, @chamados = pagy(:offset, chamados.order(Arel.sql(Ti::Chamado::ORDEM_DE_PRIORIDADE), :aberto_em, :id), limit: POR_PAGINA)
    end

    def show
      @valores = @chamado.valores.em_ordem.with_attached_arquivos
      @eventos = @chamado.eventos.em_ordem
      abrir_sobre(ti_operacao_index_path(status: (@chamado.em_andamento? ? "andamento" : "encerrados")))
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

    def filtrar(chamados, visao)
      case visao
      when "meus" then chamados.em_andamento.where(responsavel: current_user).or(chamados.em_andamento.where(triador: current_user, responsavel: nil))
      when "andamento" then chamados.em_andamento
      when "encerrados" then chamados.where.not(status: Ti::Chamado::EM_ANDAMENTO)
      else chamados.where(status: %w[aberto aguardando_tecnico], responsavel: nil)
      end
    end
  end
end
