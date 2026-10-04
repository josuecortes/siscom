module Ti
  # Solicitações de um perfil de abertura (o que os usuários dele podem abrir) ou de um grupo
  # técnico (o que os membros dele atendem). O tipo do item vem da rota.
  class SolicitacoesDoItemController < BaseController
    TEXTOS = {
      "perfil" => { ajuda: "Os usuários deste perfil podem abrir as solicitações marcadas.", volta: :ti_perfis_abertura_path },
      "grupo" => { ajuda: "Os triadores e técnicos deste grupo podem pegar os chamados das solicitações marcadas.", volta: :ti_grupos_tecnicos_path }
    }.freeze

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action :carregar

    def edit
      @marcados = @item.vinculos_de_problema.pluck(:problema_id)
    end

    def update
      resultado = Ti::Solicitacoes::DefinirDoItem.call(item: @item, ids: params[:ids], definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Solicitações de #{@item.nome} atualizadas.", voltar_para: @volta)
      else
        @erro = resultado.mensagem_de_erro
        @marcados = Array(params[:ids]).map(&:to_i)
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar
      @tipo = params[:tipo].presence_in(TEXTOS.keys) || raise(ActiveRecord::RecordNotFound)
      @item = @tipo == "perfil" ? Ti::PerfilAbertura.find(params[:perfil_abertura_id]) : Ti::GrupoTecnico.find(params[:grupo_tecnico_id])
      @volta = public_send(TEXTOS.dig(@tipo, :volta))
      @caminho = @tipo == "perfil" ? ti_perfil_abertura_solicitacoes_path(@item) : ti_grupo_tecnico_solicitacoes_path(@item)
      @por_categoria = Ti::Problema.ativo.joins(:categoria).order("ti_categorias.nome", :nome).includes(:categoria).group_by { |s| s.categoria.nome }
    end
  end
end
