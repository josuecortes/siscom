module Rh
  # RH → Pendências: o que a importação do siscom antigo deixou para conferir.
  class PendenciasController < BaseController
    POR_PAGINA = 20

    before_action { pode!("rh.pendencias.ver") }

    def index
      @filtros = { q: params[:q].to_s.strip, tipo: params[:tipo].presence_in(Rh::PendenciaImportacao::TIPOS.keys) }
      pendencias = Rh::PendenciaImportacao.abertas.joins(:pessoa).includes(:pessoa).order("rh_pessoas.nome", :tipo)
      pendencias = pendencias.where(tipo: @filtros[:tipo]) if @filtros[:tipo]
      pendencias = pendencias.merge(Rh::Pessoa.buscar(@filtros[:q])) if @filtros[:q].present?

      @totais = Rh::PendenciaImportacao.abertas.group(:tipo).count
      @pagy, @pendencias = pagy(:offset, pendencias, limit: POR_PAGINA)
    end

    # Para quando a pendência não se aplica (ex.: a pessoa realmente não tem CPF para informar).
    def resolver
      pendencia = Rh::PendenciaImportacao.abertas.find(params[:id])
      pendencia.update!(resolvida_em: Time.current)
      Core::Api.auditar(evento: "rh.pendencia.resolvida", alvo: pendencia.pessoa, dados: { tipo: pendencia.tipo })

      redirect_to rh_pendencias_path(request.query_parameters), notice: "Pendência marcada como resolvida.", status: :see_other
    end
  end
end
