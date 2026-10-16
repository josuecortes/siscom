module Ti
  # Solicitações de um perfil de abertura (o que os usuários dele podem abrir) ou de um grupo
  # técnico (o que os membros dele atendem): busca para adicionar e lista com × para tirar.
  # O tipo do item vem da rota. Cada mudança vale na hora.
  class SolicitacoesDoItemController < BaseController
    TEXTOS = {
      "perfil" => { ajuda: "Os usuários deste perfil podem abrir estas solicitações. As mudanças valem na hora.", volta: :ti_perfis_abertura_path },
      "grupo" => { ajuda: "Os triadores e técnicos deste grupo podem pegar os chamados destas solicitações. As mudanças valem na hora.",
                   volta: :ti_grupos_tecnicos_path }
    }.freeze

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action :carregar

    def edit
    end

    def create
      solicitacao = Ti::Problema.ativo.find_by(id: params[:problema_id])
      return responder(nil, erro: "Escolha uma solicitação da lista.") unless solicitacao

      responder(definir(atuais + [ solicitacao.id ]), aviso: "#{solicitacao.nome} adicionada.")
    end

    def destroy
      solicitacao = @item.problemas.find(params[:problema_id])
      responder(definir(atuais - [ solicitacao.id ]), aviso: "#{solicitacao.nome} removida.")
    end

    private

    def atuais = @item.vinculos_de_problema.pluck(:problema_id)
    def definir(ids) = Ti::Solicitacoes::DefinirDoItem.call(item: @item, ids: ids, definido_por: current_user)

    def responder(resultado, aviso: nil, erro: nil)
      @erro = erro || (resultado.mensagem_de_erro if resultado.falha?)
      @aviso = aviso unless @erro
      @item.reload
      render :edit, status: (@erro ? :unprocessable_content : :ok)
    end

    def carregar
      @tipo = params[:tipo].presence_in(TEXTOS.keys) || raise(ActiveRecord::RecordNotFound)
      @item = @tipo == "perfil" ? Ti::PerfilAbertura.find(params[:perfil_abertura_id]) : Ti::GrupoTecnico.find(params[:grupo_tecnico_id])
      @volta = public_send(TEXTOS.dig(@tipo, :volta))
      @caminho = @tipo == "perfil" ? ti_perfil_abertura_solicitacoes_path(@item) : ti_grupo_tecnico_solicitacoes_path(@item)
    end
  end
end
