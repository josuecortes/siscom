module Ti
  # TI → Grupos técnicos → aba Técnicos: o mesmo vínculo de "Gerenciar membros" visto pelo lado da pessoa.
  # Procura o técnico pelo nome ou e-mail e, no painel, inclui ou tira de vários grupos de uma vez.
  # Cada mudança vale na hora e passa por Ti::Grupos::DefinirDoUsuario (que confere a permissão, audita e avisa).
  class TecnicosDosGruposController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action(except: :index) { @usuario = ::User.ativos.find(params[:id]) }

    # Sem busca: quem já está em algum grupo. Com busca: quem pode entrar (tem permissão na TI) e quem já está em grupo.
    def index
      @busca = params[:q].to_s.strip
      membros = ::User.ativos.where(id: Ti::MembroGrupo.where(grupo_tecnico_id: Ti::GrupoTecnico.ativo.select(:id)).select(:user_id))
      usuarios = @busca.present? ? ::User.ativos.buscar(@busca).merge(Ti::Grupos.elegiveis.unscope(:order).or(membros)) : membros
      @pagy, @usuarios = pagy(:offset, usuarios.order(:nome, :id), limit: POR_PAGINA)
      ids = @usuarios.map(&:id)
      @grupos_por_usuario = Ti::MembroGrupo.joins(:grupo_tecnico).merge(Ti::GrupoTecnico.ativo).where(user_id: ids)
                                           .order("ti_grupos_tecnicos.nome").pluck(:user_id, "ti_grupos_tecnicos.nome").group_by(&:first).transform_values { |linhas| linhas.map(&:last) }
      @papeis = Core::Api.papeis_concedidos(ids, modulo: :ti)
    end

    def edit
      montar_painel
    end

    def adicionar
      ids = escolhidos
      return responder(erro: "Marque pelo menos um grupo para adicionar.") if ids.empty?

      responder(definir(atuais | ids), aviso: "#{@usuario.nome} entrou em #{ids.size} grupo(s).")
    end

    # Tira dos grupos marcados, ou só de um (o × da linha manda `so`).
    def remover
      ids = params[:so].present? ? [ params[:so].to_i ] : escolhidos
      return responder(erro: "Marque pelo menos um grupo para remover.") if ids.empty?

      responder(definir(atuais - ids), aviso: "#{@usuario.nome} saiu de #{ids.size} grupo(s).")
    end

    private

    def ativos = Ti::GrupoTecnico.ativo
    def atuais = Ti::MembroGrupo.where(user: @usuario, grupo_tecnico_id: ativos.select(:id)).pluck(:grupo_tecnico_id)
    def escolhidos = ativos.where(id: Array(params[:grupo_ids]).map(&:to_i)).pluck(:id)
    def definir(ids) = Ti::Grupos::DefinirDoUsuario.call(user: @usuario, grupo_ids: ids, definido_por: current_user)

    def responder(resultado = nil, aviso: nil, erro: nil)
      @erro = erro || (resultado.mensagem_de_erro if resultado&.falha?)
      @aviso = aviso unless @erro
      montar_painel
      render :edit, status: (@erro ? :unprocessable_content : :ok)
    end

    def montar_painel
      marcados = atuais
      @nos_grupos, @fora = ativos.ordenados.to_a.partition { |grupo| marcados.include?(grupo.id) }
      @elegivel = Ti::Grupos.elegiveis.exists?(id: @usuario.id)
      @papeis = Core::Api.papeis_concedidos([ @usuario.id ], modulo: :ti).fetch(@usuario.id, [])
    end
  end
end
