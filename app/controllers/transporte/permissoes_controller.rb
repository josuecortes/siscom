module Transporte
  # Transporte → Permissões (porta de transport-user-accesses-module.tsx): quem tem quais permissões no Transporte.
  # O usuário pode acumular papéis (ex.: técnico e motorista). Solicitante é automático para todos.
  class PermissoesController < BaseController
    POR_PAGINA = 20

    before_action { pode!("transporte.permissoes.conceder") }
    before_action :carregar_papeis
    before_action :carregar_usuario, only: %i[edit update]

    def index
      @filtros = { q: params[:q].to_s.strip, situacao: params[:situacao].presence_in(%w[com sem]) || "todos" }
      com_papel = Core::Api.ids_dos_usuarios_com_papel(modulo: :transporte)
      usuarios = ::User.ativos.order(:nome, :id)
      usuarios = usuarios.buscar(@filtros[:q]) if @filtros[:q].present?
      usuarios = usuarios.where(id: com_papel) if @filtros[:situacao] == "com"
      usuarios = usuarios.where.not(id: com_papel) if @filtros[:situacao] == "sem"

      @pagy, @usuarios = pagy(:offset, usuarios, limit: POR_PAGINA)
      @concedidos = Core::Api.papeis_concedidos(@usuarios.map(&:id), modulo: :transporte)
    end

    def edit
      @papeis_atuais = Core::Api.papeis_concedidos([ @usuario.id ], modulo: :transporte).fetch(@usuario.id, [])
    end

    def update
      escolhidos = Array(params[:papeis]).map(&:to_s) & @papeis.map(&:chave)
      resultado = Core::Api.definir_papeis(user: @usuario, modulo: :transporte, papeis: escolhidos, definido_por: current_user)

      if resultado.sucesso?
        concluir_painel(aviso: "Permissões de #{@usuario.nome} atualizadas.", voltar_para: transporte_permissoes_path)
      else
        @erro = resultado.mensagem_de_erro
        @papeis_atuais = escolhidos
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar_papeis
      @papeis = Core::Api.modulo(:transporte).papeis.values.reject(&:automatico?)
    end

    def carregar_usuario
      @usuario = ::User.ativos.find(params[:id])
    end
  end
end
