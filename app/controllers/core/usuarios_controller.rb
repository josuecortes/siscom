module Core
  # Administração → Usuários (porta de platform-users-module.tsx e services/users/*).
  class UsuariosController < BaseController
    POR_PAGINA = 20

    before_action :carregar_usuario, only: %i[edit update ativar desativar redefinir_senha]

    def index
      authorize ::User, policy_class: UsuarioPolicy
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativos inativos]) || "todos" }

      usuarios = policy_scope(::User, policy_scope_class: UsuarioPolicy::Scope).order(:nome, :id)
      usuarios = usuarios.buscar(@filtros[:q]) if @filtros[:q].present?
      usuarios = usuarios.ativos if @filtros[:status] == "ativos"
      usuarios = usuarios.inativos if @filtros[:status] == "inativos"

      @pagy, @usuarios = pagy(:offset, usuarios, limit: POR_PAGINA)
      @modulos_por_usuario = modulos_de(@usuarios)
    end

    def new
      authorize ::User, :create?, policy_class: UsuarioPolicy
      @usuario = ::User.new
    end

    def create
      authorize ::User, :create?, policy_class: UsuarioPolicy
      resultado = Usuarios::Criar.call(atributos: atributos_do_usuario, criado_por: current_user)
      @usuario = resultado.objeto

      if resultado.sucesso?
        mostrar_senha_temporaria(@usuario, @usuario.senha_temporaria, criado: true)
      else
        @erros_gerais = resultado.erros if @usuario.nil?
        @usuario ||= ::User.new(atributos_do_usuario)
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @usuario, :update?, policy_class: UsuarioPolicy
    end

    def update
      authorize @usuario, :update?, policy_class: UsuarioPolicy
      resultado = Usuarios::Atualizar.call(user: @usuario, atributos: atributos_do_usuario, atualizado_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Usuário atualizado com sucesso.", voltar_para: core_usuarios_path)
      else
        render :edit, status: :unprocessable_content
      end
    end

    def ativar = alterar_status(true, "Usuário ativado com sucesso.")
    def desativar = alterar_status(false, "Usuário desativado com sucesso.")

    def redefinir_senha
      authorize @usuario, :redefinir_senha?, policy_class: UsuarioPolicy
      resultado = Usuarios::RedefinirSenha.call(user: @usuario, redefinido_por: current_user)

      if resultado.sucesso?
        mostrar_senha_temporaria(@usuario, resultado.objeto, criado: false)
      else
        redirect_to core_usuarios_path, alert: resultado.mensagem_de_erro, status: :see_other
      end
    end

    private

    def carregar_usuario
      @usuario = ::User.find(params[:id])
    end

    def atributos_do_usuario
      params.expect(user: %i[nome email])
    end

    def alterar_status(ativo, aviso)
      authorize @usuario, :alterar_status?, policy_class: UsuarioPolicy
      resultado = Usuarios::AlterarStatus.call(user: @usuario, ativo: ativo, alterado_por: current_user)

      if resultado.sucesso?
        redirect_to core_usuarios_path(request.query_parameters), notice: aviso, status: :see_other
      else
        redirect_to core_usuarios_path, alert: resultado.mensagem_de_erro, status: :see_other
      end
    end

    # A senha temporária aparece uma única vez, no painel, para quem fez a ação.
    def mostrar_senha_temporaria(usuario, senha, criado:)
      @usuario = usuario
      @senha_temporaria = senha
      @criado = criado
      response.headers["Cache-Control"] = "no-store"
      render :senha_temporaria
    end

    # { user_id => ["Administração", "RH"] }: módulos em que o usuário tem papel concedido.
    def modulos_de(usuarios)
      Core::Concessao.ativo.where(user_id: usuarios.map(&:id)).joins(:acesso).merge(Core::Acesso.ativo)
                     .distinct.pluck(:user_id, :modulo)
                     .group_by(&:first)
                     .transform_values { |linhas| linhas.filter_map { |_, chave| Core::Catalogo.modulo(chave)&.nome }.sort }
    end
  end
end
