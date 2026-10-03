module Rh
  # RH → Lotações (porta de hr-assignments-module.tsx): quem está lotado onde.
  class LotacoesController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.lotacoes.ver") }

    def index
      @filtros = { q: params[:q].to_s.strip, status: params[:status].presence_in(%w[ativo inativo todos]) || "ativo" }
      lotacoes = Rh::Lotacao.joins(:pessoa, :unidade).includes(:pessoa, :unidade, :funcao).order("rh_pessoas.nome", data_inicio: :desc)
      lotacoes = lotacoes.where(status: @filtros[:status]) unless @filtros[:status] == "todos"
      if @filtros[:q].present?
        padrao = "%#{Rh::Lotacao.sanitize_sql_like(@filtros[:q].squish.upcase)}%"
        lotacoes = lotacoes.where("rh_pessoas.nome LIKE :p OR rh_unidades.nome LIKE :p OR rh_unidades.sigla LIKE :p", p: padrao)
      end
      @pagy, @lotacoes = pagy(:offset, lotacoes, limit: POR_PAGINA)
    end

    def encerrar
      lotacao = Rh::Lotacao.find(params[:id])
      resultado = Rh::Lotacoes::Encerrar.call(lotacao: lotacao, encerrado_por: current_user)
      raise Core::AcessoNegado, Rh::Lotacoes::Lotar::PERMISSAO if resultado.falha? && !pode?(Rh::Lotacoes::Lotar::PERMISSAO)

      opcoes = resultado.sucesso? ? { notice: "Lotação encerrada." } : { alert: resultado.mensagem_de_erro }
      redirect_back_or_to rh_pessoa_path(lotacao.pessoa), status: :see_other, **opcoes
    end
  end
end
