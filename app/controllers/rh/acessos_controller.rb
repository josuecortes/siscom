module Rh
  # RH → Acessos (porta de hr-authorizations-module.tsx): quem tem qual permissão
  # no RH. Cada usuário tem no máximo um papel concedido no módulo.
  class AcessosController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.acessos.conceder") }
    before_action :carregar_papeis
    before_action :carregar_usuario, only: %i[edit update]

    def index
      @filtros = { q: params[:q].to_s.strip, situacao: params[:situacao].presence_in(%w[com sem]) || "todos" }
      com_papel = Core::Api.ids_dos_usuarios_com_papel(modulo: :rh)
      usuarios = ::User.ativos.order(:nome, :id)
      usuarios = usuarios.buscar(@filtros[:q]) if @filtros[:q].present?
      usuarios = usuarios.where(id: com_papel) if @filtros[:situacao] == "com"
      usuarios = usuarios.where.not(id: com_papel) if @filtros[:situacao] == "sem"

      @pagy, @usuarios = pagy(:offset, usuarios, limit: POR_PAGINA)
      @concedidos = Core::Api.papeis_concedidos(@usuarios.map(&:id), modulo: :rh)
    end

    def edit
      @papel_atual = Core::Api.papeis_concedidos([ @usuario.id ], modulo: :rh).fetch(@usuario.id, []).first
    end

    def update
      resultado = Core::Api.definir_papel(user: @usuario, modulo: :rh, papel: params[:papel].presence_in(@papeis.map(&:chave)),
                                          definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Permissão de #{@usuario.nome} atualizada.", voltar_para: rh_acessos_path)
      else
        @erro = resultado.mensagem_de_erro
        @papel_atual = params[:papel]
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar_papeis
      @papeis = Core::Api.modulo(:rh).papeis.values.reject(&:automatico?)
    end

    def carregar_usuario
      @usuario = ::User.ativos.find(params[:id])
    end
  end
end
