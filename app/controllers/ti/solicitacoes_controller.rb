module Ti
  # TI → Administração → Solicitações (porta de helpdesk-solicitations-module.tsx): o catálogo
  # do que pode ser pedido à TI.
  class SolicitacoesController < BaseController
    POR_PAGINA = 20

    before_action { pode!(Ti::Catalogo::PERMISSAO) }
    before_action :carregar_solicitacao, only: %i[edit update ativar desativar]
    before_action :carregar_categorias, only: %i[new create edit update]

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo]) || "todos" }
      solicitacoes = Ti::Problema.ordenados.joins(:categoria).includes(:categoria, :perfis_abertura, :grupos_tecnicos)
      solicitacoes = solicitacoes.buscar(@filtros[:q]) if @filtros[:q].present?
      solicitacoes = solicitacoes.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      @pagy, @solicitacoes = pagy(:offset, solicitacoes, limit: POR_PAGINA)
    end

    def new
      @solicitacao = Ti::Problema.new
    end

    def create
      salvar(Ti::Problema.new, :new, "Solicitação criada com sucesso.")
    end

    def edit
    end

    def update
      salvar(@solicitacao, :edit, "Solicitação atualizada com sucesso.")
    end

    def ativar = alterar_status(true, "Solicitação ativada com sucesso.")
    def desativar = alterar_status(false, "Solicitação desativada com sucesso.")

    private

    def carregar_solicitacao
      @solicitacao = Ti::Problema.find(params[:id])
    end

    def carregar_categorias
      @categorias = Ti::Categoria.ordenados.where(status: "ativo").or(Ti::Categoria.where(id: @solicitacao&.categoria_id)).pluck(:nome, :id)
    end

    def salvar(solicitacao, tela, aviso)
      resultado = Ti::Solicitacoes::Salvar.call(solicitacao: solicitacao, atributos: params.expect(solicitacao: Ti::Solicitacoes::Salvar::CAMPOS),
                                                salvo_por: current_user)
      @solicitacao = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: ti_solicitacoes_path)
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo, aviso)
      resultado = Ti::Catalogo::AlterarStatus.call(registro: @solicitacao, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to ti_solicitacoes_path, status: :see_other, **opcoes
    end
  end
end
