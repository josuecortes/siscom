module Equipamentos
  # Equipamentos → Movimentações e Equipamentos → Empréstimos e cautelas (porta de movimentacao_equipamentos_controller.rb,
  # mais o empréstimo): os envios das unidades que a pessoa enxerga. As duas telas são a mesma; muda o tipo.
  class MovimentacoesController < BaseController
    POR_PAGINA = 20
    ABAS = { "em_andamento" => "Em andamento", "concluida" => "Concluídas", "cancelada" => "Canceladas" }.freeze

    before_action { pode!(emprestimo? ? Equipamentos::Acesso::EMPRESTAR : Equipamentos::Acesso::MOVIMENTAR) }
    before_action(only: %i[show cancelamento cancelar]) { @envio = envios.find(params[:id]) }
    helper_method :emprestimo?, :caminho_da_lista

    def index
      @filtros = filtros
      lista = filtrar(envios)
      @contagens = lista.group(:status).count
      lista = lista.where(status: @filtros[:status]) unless @filtros[:filtrando]
      @unidade = Rh::Api.unidade(@filtros[:unidade_id]) if @filtros[:unidade_id]
      @pagy, @envios = pagy(:offset, lista.includes(:itens).order(ordem), limit: POR_PAGINA)
    end

    def show
      abrir_sobre(caminho_da_lista(status: @envio.status))
    end

    def new
      # Vem da lista de equipamentos (origem_id, item_ids) ou do próprio formulário, que se recarrega ao trocar a unidade (envio[...]).
      dados = params.fetch(:envio, {}).permit(:origem_id, :destino_id, :responsavel_id, item_ids: [])
      preparar_formulario(origem_id: dados[:origem_id] || params[:origem_id], destino_id: dados[:destino_id], responsavel_id: dados[:responsavel_id], item_ids: dados[:item_ids] || params[:item_ids])
    end

    def create
      dados = params.fetch(:envio, {}).permit(:tipo, :origem_id, :destino_id, :responsavel_id, :descricao, :previsao_devolucao, item_ids: [])
      tipo = emprestimo? ? dados[:tipo].presence_in(Equipamentos::Movimentacao::DE_EMPRESTIMO) || "emprestimo" : "movimentacao"
      resultado = Equipamentos::Envios::Criar.call(tipo: tipo, origem_id: dados[:origem_id], destino_id: dados[:destino_id], responsavel_id: dados[:responsavel_id], item_ids: dados[:item_ids],
                                                   descricao: dados[:descricao], previsao_devolucao: dados[:previsao_devolucao], criada_por: current_user)
      if resultado.sucesso?
        envio = resultado.objeto
        return concluir_painel(aviso: "#{envio.nome_do_tipo} #{envio.codigo} enviada: #{envio.responsavel_nome} foi avisado(a).", voltar_para: caminho_da_lista)
      end

      @erro = resultado.mensagem_de_erro
      preparar_formulario(**dados.to_h.symbolize_keys.slice(:origem_id, :destino_id, :responsavel_id, :item_ids))
      render :new, status: :unprocessable_content
    end

    def cancelamento
    end

    # Deixa de enviar um equipamento ainda não recebido (`item_id`), ou todos os pendentes.
    def cancelar
      resultado = Equipamentos::Envios::Operar.call(envio: @envio, acao: "cancelar_item", ator: current_user, item_id: params[:item_id].presence)
      return concluir_painel(aviso: "Envio cancelado para o(s) equipamento(s) escolhido(s).", voltar_para: caminho_da_lista) if resultado.sucesso?

      @erro = resultado.mensagem_de_erro
      render :cancelamento, status: :unprocessable_content
    end

    private

    def emprestimo? = params[:emprestimo].present?
    def caminho_da_lista(**opcoes) = emprestimo? ? equipamentos_emprestimos_path(**opcoes) : equipamentos_movimentacoes_path(**opcoes)
    def envios = Equipamentos::Acesso.envios_visiveis(current_user).then { |lista| emprestimo? ? lista.emprestimos : lista.definitivas }

    def filtros
      valores = { q: params[:q].to_s.strip, unidade_id: params[:unidade_id].presence&.to_i, atrasados: (params[:atrasados] == "1" if emprestimo?),
                  criado_de: DataBr.interpretar(params[:criado_de]), criado_ate: DataBr.interpretar(params[:criado_ate]) }
      valores.merge(status: params[:status].presence_in(ABAS.keys) || "em_andamento", ordem: params[:ordem].presence_in(%w[criado previsao]),
                    direcao: params[:direcao].presence_in(%w[asc desc]) || "desc", filtrando: valores.values.any?(&:present?))
    end

    # Texto: código do envio, nomes (quem recebe, quem criou, unidades) e qualquer dado dos equipamentos do envio.
    def filtrar(lista)
      f = @filtros
      if f[:q].present?
        com_equipamento = Equipamentos::ItemMovimentacao.where(item_id: Equipamentos::Item.buscar(f[:q]).select(:id)).select(:movimentacao_id)
        lista = lista.where(Busca.em(%w[codigo responsavel_nome criada_por_nome origem_nome destino_nome].map { |coluna| "equipamentos_movimentacoes.#{coluna}" }), t: Busca.padrao(f[:q]))
                     .or(lista.where(id: com_equipamento))
      end
      lista = lista.das_unidades(f[:unidade_id]) if f[:unidade_id]
      lista = lista.where(status: "em_andamento").where.not(aceita_em: nil).where(previsao_devolucao: ...Date.current) if f[:atrasados]
      lista = lista.where(created_at: (f[:criado_de]&.in_time_zone&.beginning_of_day)..(f[:criado_ate]&.in_time_zone&.end_of_day)) if f[:criado_de] || f[:criado_ate]
      lista
    end

    def ordem
      coluna = @filtros[:ordem] == "previsao" ? :previsao_devolucao : :created_at
      { coluna => (@filtros[:ordem] ? @filtros[:direcao].to_sym : :desc), id: :desc }
    end

    # Origem: as unidades em que a pessoa age (o administrador escolhe qualquer uma por busca).
    def preparar_formulario(origem_id: nil, destino_id: nil, responsavel_id: nil, item_ids: nil)
      @todas = Equipamentos::Acesso.todas?(current_user)
      @unidades = Equipamentos::Acesso.unidades_de(current_user)
      @origem = Rh::Api.unidade(origem_id.presence || (@unidades.first.id if @unidades.one? && !@todas))
      @origem = nil unless @origem && Equipamentos::Acesso.age_na_unidade?(current_user, @origem.id)
      @destino = Rh::Api.unidade(destino_id)
      @responsavel = ::User.ativos.find_by(id: responsavel_id) if @destino
      @marcados = Array(item_ids).map(&:to_i)
      @itens = @origem ? Equipamentos::Item.where(rh_unidade_id: @origem.id, status: "ativo").em_ordem.to_a : []
      @presos = Equipamentos::ItemMovimentacao.abertos.where(item_id: @itens.reject(&:disponivel?).map(&:id)).includes(:movimentacao).index_by(&:item_id)
    end
  end
end
