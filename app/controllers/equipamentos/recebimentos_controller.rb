module Equipamentos
  # Minha área → Meus equipamentos: o que tenho para receber, os empréstimos para aceitar, o que está comigo
  # emprestado (para devolver) e as devoluções para eu receber. É de todo usuário.
  # O administrador de Equipamentos pode fazer essas ações em nome da pessoa (fica registrado).
  class RecebimentosController < BaseController
    POR_PAGINA = 20
    # Abas de Meus equipamentos. As duas de histórico (Recebidos e Devolvidos) são o registro de quem só recebe e devolve.
    ABAS = { "receber" => "Para receber", "recebidos" => "Recebidos e não recebidos", "comigo" => "Comigo para devolver", "devolvidos" => "Devolvidos" }.freeze
    COMIGO = %w[emprestado devolucao_pendente].freeze
    JA_PASSARAM = %w[recebido cancelado emprestado devolucao_pendente devolvido].freeze

    before_action { pode!("equipamentos.receber") }
    before_action(except: :index) { @envio = meus_envios.find(params[:id]) }
    before_action(only: %i[termo devolucao recebimento_da_devolucao]) { abrir_sobre(volta) }
    helper_method :volta

    def index
      @aba = params[:aba].presence_in(ABAS.keys) || "receber"
      @q = params[:q].to_s.strip
      @contagens = { "receber" => buscar_linhas(linhas_comigo.pendente).count + buscar_linhas(devolucoes_para_mim).count, "recebidos" => buscar_linhas(historico).count,
                     "comigo" => buscar_linhas(linhas_comigo.where(status: COMIGO)).count, "devolvidos" => buscar_linhas(devolvidos).count }
      case @aba
      when "receber" then @pagy, @envios = pagy(:offset, buscar_envios(para_receber).includes(itens: :item).order(:created_at, :id), limit: POR_PAGINA)
      when "comigo" then @pagy, @envios = pagy(:offset, buscar_envios(comigo).includes(itens: :item).order(:previsao_devolucao, :id), limit: POR_PAGINA)
      when "recebidos" then @pagy, @linhas = pagy(:offset, buscar_linhas(historico).includes(:item, :movimentacao, :recebido_por, :cancelado_por, :devolucao_recebida_por).order(updated_at: :desc, id: :desc), limit: POR_PAGINA)
      when "devolvidos" then @pagy, @linhas = pagy(:offset, buscar_linhas(devolvidos).includes(:item, :movimentacao, :devolucao_recebida_por).order(devolvido_em: :desc, id: :desc), limit: POR_PAGINA)
      end
    end

    def receber
      operar "receber_item", "Recebimento registrado.", item_id: params[:item_id].presence
    end

    def termo
      @texto = @envio.aceita? ? @envio.termo : Equipamentos::Envios::Termo.texto(@envio)
    end

    def aceitar
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "aceitar", ator: current_user), :termo, "Termo aceito: os equipamentos estão sob a sua responsabilidade."
    end

    def devolucao
    end

    def devolver
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "devolver", ator: current_user, para_id: params[:para_id]), :devolucao,
                "Devolução iniciada: a pessoa indicada foi avisada e precisa confirmar o recebimento."
    end

    def recebimento_da_devolucao
    end

    def receber_devolucao
      responder Equipamentos::Envios::Operar.call(envio: @envio, acao: "receber_devolucao", ator: current_user, observacao: params[:observacao]), :recebimento_da_devolucao,
                "Devolução recebida: o equipamento voltou para a unidade."
    end

    private

    def linhas = Equipamentos::ItemMovimentacao.joins(:movimentacao)
    # Equipamentos dos envios feitos para mim (em qualquer situação do envio).
    def linhas_comigo = linhas.where(equipamentos_movimentacoes: { responsavel_id: current_user.id })
    def devolucoes_para_mim = linhas.where(status: "devolucao_pendente", devolver_para_id: current_user.id)
    # O que já recebi (movimentação ou empréstimo), o que foi cancelado antes de eu receber e as devoluções que recebi de volta.
    def historico = linhas_comigo.where(status: JA_PASSARAM).or(linhas.where(devolucao_recebida_por_id: current_user.id))
    def devolvidos = linhas_comigo.devolvido
    def em_andamento = Equipamentos::Movimentacao.em_andamento

    # Envios com algo para eu receber: o recebido de uma movimentação, o termo de um empréstimo, ou uma devolução.
    def para_receber
      em_andamento.where(id: linhas_comigo.pendente.select(:movimentacao_id)).or(em_andamento.where(id: devolucoes_para_mim.select(:movimentacao_id)))
    end

    def comigo = em_andamento.where(id: linhas_comigo.where(status: COMIGO).select(:movimentacao_id))

    # Busca: código do envio, nomes (unidades, quem enviou, quem recebe) e qualquer dado do equipamento.
    DO_ENVIO = %w[codigo origem_nome destino_nome criada_por_nome responsavel_nome].map { |coluna| "UPPER(equipamentos_movimentacoes.#{coluna}) LIKE :t" }.join(" OR ").freeze

    def padrao = "%#{Equipamentos::Movimentacao.sanitize_sql_like(@q.squish.upcase)}%"

    def buscar_envios(envios)
      return envios if @q.blank?

      com_equipamento = Equipamentos::ItemMovimentacao.where(item_id: Equipamentos::Item.buscar(@q).select(:id)).select(:movimentacao_id)
      envios.where(DO_ENVIO, t: padrao).or(envios.where(id: com_equipamento))
    end

    def buscar_linhas(relacao)
      return relacao if @q.blank?

      relacao.where(DO_ENVIO, t: padrao).or(relacao.where(item_id: Equipamentos::Item.buscar(@q).select(:id)))
    end

    # Os envios em que sou quem recebe, ou quem recebe a devolução; o administrador, todos.
    def meus_envios
      return Equipamentos::Movimentacao.all if Equipamentos::Acesso.pode?(current_user, Equipamentos::Acesso::ADMINISTRAR)

      Equipamentos::Movimentacao.where(responsavel: current_user)
                                .or(Equipamentos::Movimentacao.where(id: Equipamentos::ItemMovimentacao.where(devolver_para: current_user).select(:movimentacao_id)))
    end

    # Para onde o painel volta: a lista do módulo (administrador), ou a aba de Meus equipamentos de onde veio.
    def volta
      return @envio.emprestimo? ? equipamentos_emprestimos_path : equipamentos_movimentacoes_path if params[:voltar] == "lista"

      equipamentos_recebimentos_path(aba: params[:voltar].presence_in(ABAS.keys - [ "receber" ]))
    end

    def operar(acao, aviso, **outros)
      resultado = Equipamentos::Envios::Operar.call(envio: @envio, acao: acao, ator: current_user, **outros)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }
      redirect_to volta, status: :see_other, **opcoes
    end

    def responder(resultado, tela, aviso)
      return concluir_painel(aviso: aviso, voltar_para: volta) if resultado.sucesso?

      @erro = resultado.mensagem_de_erro
      @texto = @envio.aceita? ? @envio.termo : Equipamentos::Envios::Termo.texto(@envio)
      render tela, status: :unprocessable_content
    end
  end
end
