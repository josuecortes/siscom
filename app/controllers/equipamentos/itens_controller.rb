module Equipamentos
  # Equipamentos → Equipamentos (porta de equipamentos_controller.rb do siscom antigo): lista com filtros e Excel,
  # ver (painel com o histórico), cadastro individual ou em kit, edição, mudança de situação e kit.
  class ItensController < BaseController
    POR_PAGINA = 20
    # Filtro de situação: por padrão, o que está em uso (os descartados ficam fora do dia a dia).
    STATUS = { "em_uso" => "Em uso (sem descartados)", "todos" => "Todos" }.merge(Equipamentos::Item::STATUS).freeze
    ORDENS = { "cadastro" => "created_at", "tipo" => "tipo_equipamento" }.freeze

    before_action { pode!(Equipamentos::Acesso::VER) }
    before_action(only: %i[new create]) { pode!(Equipamentos::Acesso::GERENCIAR) }
    before_action(only: %i[show edit update situacao mudar_situacao kit_do_item entrar_no_kit sair_do_kit]) { @item = Equipamentos::Acesso.itens_visiveis(current_user).find(params[:id]) }
    before_action(only: %i[edit update situacao mudar_situacao kit_do_item entrar_no_kit sair_do_kit]) { raise Core::AcessoNegado unless Equipamentos::Acesso.pode_gerenciar?(current_user, @item) }

    def index
      @filtros = filtros
      itens = filtrar(Equipamentos::Acesso.itens_visiveis(current_user))
      @unidade = Rh::Api.unidade(@filtros[:unidade_id]) if @filtros[:unidade_id]
      return exportar(itens) if params[:format] == "xlsx"

      @pagy, @itens = pagy(:offset, itens.order(ordem), limit: POR_PAGINA)
      @envios = envios_abertos(@itens)
      @minhas_unidades = Equipamentos::Acesso.ids_das_unidades_de(current_user)
    end

    def show
      @eventos = @item.eventos.em_ordem
      @envio = envios_abertos([ @item ])[@item.id]
      abrir_sobre(equipamentos_itens_path)
    end

    def new
      @item = Equipamentos::Item.new
      @modo = params[:modo] == "kit" ? "kit" : "individual"
      @pecas = [ Equipamentos::Item.new ]
      preparar_formulario
    end

    def create
      @modo = params[:modo] == "kit" ? "kit" : "individual"
      @modo == "kit" ? criar_kit : criar_individual
    end

    def edit
      preparar_formulario
    end

    def update
      resultado = Equipamentos::Itens::Salvar.call(item: @item, atributos: atributos_do_item, salvo_por: current_user)
      return concluir_painel(aviso: "Equipamento atualizado com sucesso.", voltar_para: equipamentos_itens_path) if resultado.sucesso?

      preparar_formulario
      render :edit, status: :unprocessable_content
    end

    def situacao
    end

    def mudar_situacao
      responder Equipamentos::Itens::MudarSituacao.call(item: @item, status: params[:status], motivo: params[:motivo], ator: current_user), :situacao, "Situação do equipamento alterada."
    end

    # Painel do kit de um equipamento: entrar num kit pelo código, ou sair do kit em que está.
    def kit_do_item
    end

    def entrar_no_kit
      responder Equipamentos::Itens::Kit.entrar(item: @item, codigo: params[:codigo_kit], ator: current_user), :kit_do_item, "Equipamento incluído no kit."
    end

    def sair_do_kit
      responder Equipamentos::Itens::Kit.sair(item: @item, ator: current_user), :kit_do_item, "Equipamento retirado do kit."
    end

    # Confere um código de kit antes de incluir (JSON).
    def kit
      render json: Equipamentos::Itens::Kit.resumo(params[:codigo_kit]) || { encontrado: false }
    end

    # Equipamentos de uma unidade para montar um envio (JSON): todos os ativos, com a marca de quem está preso em outro envio.
    def opcoes
      raise Core::AcessoNegado unless Equipamentos::Acesso.age_na_unidade?(current_user, params[:unidade_id].to_i)

      itens = Equipamentos::Item.where(rh_unidade_id: params[:unidade_id], status: "ativo").em_ordem
      render json: itens.map { |item| { id: item.id, nome: item.nome, identificacao: item.identificacao, kit: item.identificacao_kit, codigo_kit: item.codigo_kit, livre: item.livre?, situacao: item.nome_da_situacao } }
    end

    private

    def filtros
      { q: params[:q].to_s.strip, status: params[:status].presence_in(STATUS.keys) || "em_uso", situacao: params[:situacao].presence_in(Equipamentos::Item::SITUACOES.keys),
        tipo_equipamento: params[:tipo_equipamento].presence_in(Equipamentos::Item::TIPOS), unidade_id: params[:unidade_id].presence&.to_i, contrato: params[:contrato].to_s.strip.presence,
        processo: params[:processo].to_s.strip.presence, codigo_kit: params[:codigo_kit].to_s.strip.presence,
        ordem: params[:ordem].presence_in(ORDENS.keys), direcao: params[:direcao].presence_in(%w[asc desc]) || "asc" }
    end

    def filtrar(itens)
      f = @filtros
      itens = itens.buscar(f[:q]) if f[:q].present?
      itens = f[:status] == "em_uso" ? itens.where.not(status: "descartado") : itens.where(status: f[:status]) unless f[:status] == "todos"
      itens = itens.where(situacao: f[:situacao]) if f[:situacao]
      itens = itens.where(tipo_equipamento: f[:tipo_equipamento]) if f[:tipo_equipamento]
      itens = itens.das_unidades(f[:unidade_id]) if f[:unidade_id]
      %i[contrato processo codigo_kit].each do |campo|
        itens = itens.where(Busca.em("equipamentos_itens.#{campo}"), t: Busca.padrao(f[campo])) if f[campo]
      end
      itens
    end

    # Sem escolha no cabeçalho: os mais novos primeiro (como no siscom antigo).
    def ordem
      return { created_at: :desc, id: :desc } unless @filtros[:ordem]

      { ORDENS.fetch(@filtros[:ordem]) => @filtros[:direcao].to_sym, id: :asc }
    end

    # { id do equipamento => linha do envio aberto } (para dizer com quem está e para onde vai).
    def envios_abertos(itens)
      Equipamentos::ItemMovimentacao.abertos.where(item_id: itens.map(&:id)).includes(:movimentacao).index_by(&:item_id)
    end

    def exportar(itens)
      Core::Api.auditar(evento: "equipamentos.itens.exportados", dados: { filtros: @filtros.compact_blank.except(:direcao), quantidade: itens.count }, ator: current_user)
      send_data Equipamentos::Itens::Planilha.gerar(itens.em_ordem, gerado_por: current_user), filename: "equipamentos-#{Time.current.strftime('%Y%m%d-%H%M')}.xlsx",
                                                                                         type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    def atributos_do_item = params.fetch(:item, {}).permit(*Equipamentos::Item::CAMPOS.keys, :rh_unidade_id)

    def criar_individual
      resultado = Equipamentos::Itens::Salvar.call(item: Equipamentos::Item.new, atributos: atributos_do_item, salvo_por: current_user)
      @item = resultado.objeto
      return concluir_painel(aviso: "Equipamento cadastrado com sucesso.", voltar_para: equipamentos_itens_path) if resultado.sucesso?

      @pecas = [ Equipamentos::Item.new ]
      preparar_formulario
      render :new, status: :unprocessable_content
    end

    def criar_kit
      dados = params.fetch(:kit, {}).permit(:identificacao_kit, :rh_unidade_id, *Equipamentos::Itens::CadastrarKit::COMUNS)
      pecas = (params[:pecas] || {}).values.map { |peca| peca.permit(*Equipamentos::Itens::CadastrarKit::DA_PECA).to_h }
      resultado = Equipamentos::Itens::CadastrarKit.call(atributos: dados, pecas: pecas, salvo_por: current_user)
      return concluir_painel(aviso: "Kit cadastrado com #{resultado.objeto.size} peça(s).", voltar_para: equipamentos_itens_path) if resultado.sucesso?

      @erro = resultado.mensagem_de_erro
      @kit = dados
      @pecas = resultado.objeto.presence || [ Equipamentos::Item.new ]
      @item = Equipamentos::Item.new
      preparar_formulario
      render :new, status: :unprocessable_content
    end

    # Unidades em que a pessoa pode cadastrar (o administrador escolhe por busca) e as sugestões dos campos de texto.
    def preparar_formulario
      @todas = Equipamentos::Acesso.todas?(current_user)
      @unidades = Equipamentos::Acesso.unidades_de(current_user)
      visiveis = Equipamentos::Acesso.itens_visiveis(current_user)
      @sugestoes = %i[marca modelo contrato processo].index_with { |campo| visiveis.where.not(campo => [ nil, "" ]).distinct.order(campo).limit(300).pluck(campo) }
    end

    def responder(resultado, tela, aviso)
      return concluir_painel(aviso: aviso, voltar_para: equipamentos_itens_path) if resultado.sucesso?

      @erro = resultado.mensagem_de_erro
      render tela, status: :unprocessable_content
    end
  end
end
