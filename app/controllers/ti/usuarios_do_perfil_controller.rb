module Ti
  # Usuários de um perfil de abertura (quem pode abrir as solicitações dele): busca para adicionar
  # e lista com × para tirar. Cada mudança vale na hora. Perfil padrão vale para todos e não tem lista.
  class UsuariosDoPerfilController < BaseController
    LIMITE = 50

    before_action { pode!(Ti::Perfis::DefinirDoUsuario::PERMISSAO) }
    before_action { @perfil = Ti::PerfilAbertura.find(params[:perfil_abertura_id]) }

    def edit
      montar_painel
    end

    def create
      usuario = ::User.ativos.find_by(id: params[:user_id])
      return responder(nil, erro: "Escolha um usuário da lista.") unless usuario && !@perfil.padrao?

      responder(definir(usuario, perfis_de(usuario) + [ @perfil.id ]), aviso: "#{usuario.nome} entrou no perfil.")
    end

    def destroy
      usuario = @perfil.usuarios.find(params[:user_id])
      responder(definir(usuario, perfis_de(usuario) - [ @perfil.id ]), aviso: "#{usuario.nome} saiu do perfil.")
    end

    private

    def perfis_de(usuario) = Ti::PerfilUsuario.where(user: usuario).pluck(:perfil_abertura_id)
    def definir(usuario, ids) = Ti::Perfis::DefinirDoUsuario.call(user: usuario, perfil_ids: ids, definido_por: current_user)

    def responder(resultado, aviso: nil, erro: nil)
      @erro = erro || (resultado.mensagem_de_erro if resultado.falha?)
      @aviso = aviso unless @erro
      montar_painel
      render :edit, status: (@erro ? :unprocessable_content : :ok)
    end

    def montar_painel
      @busca = params[:q].to_s.strip
      usuarios = @perfil.usuarios.order(:nome, :id)
      usuarios = usuarios.buscar(@busca) if @busca.present?
      @total = usuarios.count
      @usuarios = usuarios.limit(LIMITE).to_a
    end
  end
end
