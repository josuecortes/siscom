module Rh
  # RH → Unidades (porta de components/hr: unidades organizacionais).
  class UnidadesController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.unidades.ver") }
    before_action(only: %i[new create edit update ativar desativar]) { pode!("rh.unidades.gerenciar") }
    before_action :carregar_unidade, only: %i[edit update ativar desativar]

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo]) || "todos" }
      unidades = Rh::Unidade.ordenadas.includes(:tipo_unidade, :pai)
      unidades = unidades.buscar(@filtros[:q]) if @filtros[:q].present?
      unidades = unidades.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      @pagy, @unidades = pagy(:offset, unidades, limit: POR_PAGINA)
      @lotados = Rh::Lotacao.ativo.where(unidade_id: @unidades.map(&:id)).group(:unidade_id).count
    end

    def new
      @unidade = Rh::Unidade.new
    end

    def create
      salvar(Rh::Unidade.new, :new, "Unidade criada com sucesso.")
    end

    def edit
    end

    def update
      salvar(@unidade, :edit, "Unidade atualizada com sucesso.")
    end

    def ativar = alterar_status(true, "Unidade ativada com sucesso.")
    def desativar = alterar_status(false, "Unidade desativada com sucesso.")

    private

    def carregar_unidade
      @unidade = Rh::Unidade.find(params[:id])
    end

    def salvar(unidade, tela, aviso)
      atributos = params.expect(unidade: [ :nome, :sigla, :tipo_unidade_id, :tipo_local_id, :pai_id, { dados_escola: %i[nae codigo_inep endereco] } ])
      resultado = Rh::Unidades::Salvar.call(unidade: unidade, atributos: atributos, salvo_por: current_user)
      @unidade = resultado.objeto

      if resultado.sucesso?
        concluir_painel(aviso: aviso, voltar_para: rh_unidades_path)
      else
        render tela, status: :unprocessable_content
      end
    end

    def alterar_status(ativo, aviso)
      resultado = Rh::Unidades::AlterarStatus.call(unidade: @unidade, ativo: ativo, alterado_por: current_user)
      opcoes = resultado.sucesso? ? { notice: aviso } : { alert: resultado.mensagem_de_erro }

      redirect_to rh_unidades_path(request.query_parameters), status: :see_other, **opcoes
    end
  end
end
