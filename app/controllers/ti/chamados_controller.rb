module Ti
  # TI → Meus chamados (porta de helpdesk-tickets-module.tsx): o solicitante abre e acompanha
  # os próprios chamados.
  class ChamadosController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO) }
    before_action(only: %i[resposta responder edit update finalizacao finalizar cancelamento cancelar]) do
      @chamado = Ti::Chamado.where(solicitante: current_user).find(params[:id])
    end

    # Abas por etapa, com a quantidade de cada uma (como no seed).
    ABAS = { "aberto" => "Abertos", "em_triagem" => "Em triagem", "aguardando_solicitante" => "Ajustes", "aguardando_tecnico" => "Aguardando técnico",
             "em_atendimento" => "Em andamento", "impedido" => "Impedidos", "concluido" => "Concluídos", "finalizado" => "Finalizados",
             "cancelado" => "Cancelados" }.freeze

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(ABAS.keys) || "aberto" }
      chamados = Ti::Chamado.where(solicitante: current_user)
      chamados = chamados.buscar(@filtros[:q]) if @filtros[:q].present?
      @contagens = chamados.group(:status).count
      # Com busca, as abas dão lugar à aba única "Resultado", com os chamados de todas as etapas.
      chamados = chamados.where(status: @filtros[:status]) if @filtros[:q].blank?
      @pagy, @chamados = pagy(:offset, chamados.recentes.includes(:problema, :responsavel), limit: POR_PAGINA)
    end

    def show
      @chamado = Ti::Chamado.where(solicitante: current_user).or(Ti::Chamado.where(aberto_por: current_user)).find(params[:id])
      @valores = @chamado.valores.em_ordem.with_attached_arquivos
      @eventos = @chamado.eventos.em_ordem
      abrir_sobre(ti_chamados_path(status: @chamado.status))
    end

    # Resposta do solicitante ao pedido de ajuste da operação.
    def resposta
    end

    def responder
      resultado = Ti::Chamados::Responder.call(chamado: @chamado, user: current_user, nota: params[:nota])

      if resultado.sucesso?
        concluir_painel(aviso: "Resposta enviada. O chamado #{@chamado.codigo} voltou para a TI.", voltar_para: ti_chamados_path)
      else
        @erro = resultado.mensagem_de_erro
        render :resposta, status: :unprocessable_content
      end
    end

    # Editar as respostas do formulário (chamado aberto, ou quando a TI pediu ajuste).
    def edit
      raise Core::AcessoNegado unless @chamado.editavel_pelo_solicitante?

      @respostas = Ti::Chamados::Respostas.new(@chamado.problema, Ti::Chamados::Ajustar.entradas_atuais(@chamado))
      @erros = {}
    end

    def update
      resultado = Ti::Chamados::Ajustar.call(chamado: @chamado, user: current_user, respostas: params[:campos])

      if resultado.sucesso?
        concluir_painel(aviso: "Chamado #{@chamado.codigo} atualizado.", voltar_para: ti_chamados_path)
      else
        raise Core::AcessoNegado if resultado.objeto.nil?

        @respostas = resultado.objeto
        @erros = @respostas.erros
        render :edit, status: :unprocessable_content
      end
    end

    def finalizacao
    end

    def finalizar
      resultado = Ti::Chamados::Finalizar.call(chamado: @chamado, user: current_user, resolvido: params[:resolvido], avaliacao: params[:avaliacao],
                                               comentario: params[:comentario])
      encerrar(resultado, :finalizacao, "Chamado #{@chamado.codigo} finalizado. Obrigado pela avaliação.")
    end

    def cancelamento
    end

    def cancelar
      resultado = Ti::Chamados::Cancelar.call(chamado: @chamado, user: current_user, motivo: params[:motivo])
      encerrar(resultado, :cancelamento, "Chamado #{@chamado.codigo} cancelado.")
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

    def encerrar(resultado, tela, aviso)
      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: ti_chamados_path)
      else
        @erro = resultado.mensagem_de_erro
        render tela, status: :unprocessable_content
      end
    end

    def carregar_solicitacoes
      @solicitacoes = Ti::Problema.que_pode_abrir(current_user).ordenados.pluck(:nome, :id)
    end
  end
end
