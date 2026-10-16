module Ti
  # TI → Perfis de abertura → aba Usuários: o mesmo vínculo de "Gerenciar usuários" visto pelo lado da pessoa.
  # Procura o usuário pelo nome ou e-mail e, no painel, inclui ou tira de vários perfis de uma vez.
  # Cada mudança vale na hora e passa por Ti::Perfis::DefinirDoUsuario (que confere a permissão e audita).
  class UsuariosDosPerfisController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Perfis::DefinirDoUsuario::PERMISSAO) }
    before_action(except: :index) { @usuario = ::User.ativos.find(params[:id]) }

    # Sem busca: quem já está em algum perfil. Com busca: todos os usuários ativos que combinam.
    def index
      @busca = params[:q].to_s.strip
      usuarios = @busca.present? ? ::User.ativos.buscar(@busca) : ::User.ativos.where(id: Ti::PerfilUsuario.where(perfil_abertura_id: editaveis.select(:id)).select(:user_id))
      @pagy, @usuarios = pagy(:offset, usuarios.order(:nome, :id), limit: POR_PAGINA)
      @perfis_por_usuario = Ti::PerfilUsuario.joins(:perfil_abertura).merge(editaveis).where(user_id: @usuarios.map(&:id))
                                             .order("ti_perfis_abertura.nome").pluck(:user_id, "ti_perfis_abertura.nome").group_by(&:first).transform_values { |linhas| linhas.map(&:last) }
    end

    def edit
      montar_painel
    end

    def adicionar
      ids = escolhidos
      return responder(erro: "Marque pelo menos um perfil para adicionar.") if ids.empty?

      responder(definir(atuais | ids), aviso: "#{@usuario.nome} entrou em #{ids.size} perfil(is).")
    end

    # Tira os perfis marcados, ou só um (o × da linha manda `so`).
    def remover
      ids = params[:so].present? ? [ params[:so].to_i ] : escolhidos
      return responder(erro: "Marque pelo menos um perfil para remover.") if ids.empty?

      responder(definir(atuais - ids), aviso: "#{@usuario.nome} saiu de #{ids.size} perfil(is).")
    end

    private

    # Perfis que se mexem aqui: ativos e não padrão (o padrão vale para todos, sem lista).
    def editaveis = Ti::PerfilAbertura.ativo.where(padrao: false)
    def atuais = Ti::PerfilUsuario.where(user: @usuario, perfil_abertura_id: editaveis.select(:id)).pluck(:perfil_abertura_id)
    def escolhidos = editaveis.where(id: Array(params[:perfil_ids]).map(&:to_i)).pluck(:id)
    def definir(ids) = Ti::Perfis::DefinirDoUsuario.call(user: @usuario, perfil_ids: ids, definido_por: current_user)

    def responder(resultado = nil, aviso: nil, erro: nil)
      @erro = erro || (resultado.mensagem_de_erro if resultado&.falha?)
      @aviso = aviso unless @erro
      montar_painel
      render :edit, status: (@erro ? :unprocessable_content : :ok)
    end

    def montar_painel
      perfis = editaveis.ordenados.to_a
      marcados = atuais
      @nos_perfis, @fora = perfis.partition { |perfil| marcados.include?(perfil.id) }
      @padrao = Ti::PerfilAbertura.ativo.where(padrao: true).ordenados.to_a
    end
  end
end
