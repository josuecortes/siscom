module Ti
  # Opções dos campos de busca dos formulários de chamado, em JSON. As opções vêm da fonte de
  # referência escolhida no campo; só responde para campos de solicitações que o usuário pode abrir.
  class OpcoesController < BaseController
    LIMITE = 50
    MINIMO = 3

    before_action { pode!(Ti::Chamados::Abrir::PERMISSAO) }

    # Usuários ativos, para quem abre chamado em nome de outra pessoa.
    def usuarios
      pode!(Ti::Chamados::Abrir::PERMISSAO_PARA_OUTRO)
      render json: pessoas(::User.ativos.where.not(id: current_user.id).order(:nome, :id))
    end

    # Quem pode entrar em um grupo técnico: usuários com permissão na TI que ainda não são membros dele.
    def operadores
      pode!(Ti::Catalogo::PERMISSAO)
      render json: pessoas(Ti::Grupos.elegiveis.where.not(id: Ti::MembroGrupo.where(grupo_tecnico_id: params[:grupo_id]).select(:user_id)))
    end

    # Usuários ativos que ainda não estão em um perfil de abertura.
    def usuarios_do_perfil
      pode!(Ti::Perfis::DefinirDoUsuario::PERMISSAO)
      render json: pessoas(::User.ativos.where.not(id: Ti::PerfilUsuario.where(perfil_abertura_id: params[:perfil_id]).select(:user_id)).order(:nome, :id))
    end

    # Solicitações ativas que ainda não estão no perfil de abertura (ou no grupo técnico).
    def solicitacoes
      pode!(Ti::Catalogo::PERMISSAO)
      vinculadas = params[:tipo] == "grupo" ? Ti::ProblemaGrupo.where(grupo_tecnico_id: params[:id]) : Ti::ProblemaPerfil.where(perfil_abertura_id: params[:id])
      fora = Ti::Problema.ativo.joins(:categoria).where.not(id: vinculadas.select(:problema_id)).order(:nome)
      termo = params[:q].to_s.squish
      achadas = termo.length >= MINIMO ? fora.buscar(termo) : fora.none
      todas = achadas.none?
      escolhidas = todas ? fora : achadas

      render json: { opcoes: escolhidas.limit(LIMITE).pluck(:id, :nome, "ti_categorias.nome").map { |id, nome, categoria| { valor: id, rotulo: nome, subtitulo: categoria } },
                     todas: todas, restantes: [ escolhidas.count - LIMITE, 0 ].max }
    end

    # Unidades do RH, para o filtro "Unidade de quem pediu" da Operação.
    def unidades
      raise Core::AcessoNegado unless Ti::Chamados::Acesso.opera?(current_user)

      render json: Rh::Api.opcoes_de_unidades(params[:q])
    end

    # Quem abre em nome de outra pessoa (`solicitante_id`) vê os campos das solicitações dela.
    def index
      campo = Ti::CampoProblema.ativo.where(problema_id: Ti::Problema.que_pode_abrir(dono_do_chamado).select(:id)).find(params[:campo_id])
      raise ActiveRecord::RecordNotFound unless campo.com_fonte?

      termo = params[:q].to_s.squish
      achadas = termo.length >= MINIMO ? Core::Api.opcoes_da_fonte(campo.fonte, termo: termo, limite: LIMITE) : []
      todas = achadas.empty?
      opcoes = todas ? Core::Api.opcoes_da_fonte(campo.fonte, limite: LIMITE) : achadas

      render json: { opcoes: opcoes, todas: todas, restantes: 0 }
    end

    private

    # Resposta padrão de uma busca de pessoas: com 3 letras ou mais, quem combina; senão, a lista em ordem.
    def pessoas(relacao)
      termo = params[:q].to_s.squish
      achados = termo.length >= MINIMO ? relacao.buscar(termo) : relacao.none
      todas = achados.none?
      escolhidos = todas ? relacao : achados

      { opcoes: escolhidos.limit(LIMITE).map { |user| { valor: user.id, rotulo: user.nome, subtitulo: user.email } },
        todas: todas, restantes: [ escolhidos.count - LIMITE, 0 ].max }
    end

    def dono_do_chamado
      return current_user if params[:solicitante_id].blank?

      pode!(Ti::Chamados::Abrir::PERMISSAO_PARA_OUTRO)
      ::User.ativos.find(params[:solicitante_id])
    end
  end
end
