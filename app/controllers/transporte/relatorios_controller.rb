module Transporte
  # Transporte → Relatórios (porta de transport-reports-module.tsx): por solicitação, veículo ou
  # motorista, num período, com exportação para Excel.
  class RelatoriosController < BaseController
    before_action { pode!("transporte.relatorios.ver") }

    def show
      @filtros = params.permit(:tipo, :inicio, :fim, :status, :motorista_id, :veiculo_id, :q).to_h.symbolize_keys
      @relatorio = Transporte::Relatorios::Consultar.call(tipo: @filtros[:tipo], filtros: @filtros)
      return unless params[:format] == "xlsx"

      Core::Api.auditar(evento: "transporte.relatorio.exportado", dados: { tipo: @relatorio.tipo, inicio: @relatorio.inicio, fim: @relatorio.fim }, ator: current_user)
      send_data Transporte::Relatorios::Planilha.gerar(@relatorio), filename: "transporte-#{@relatorio.tipo}-#{Time.current.strftime('%Y%m%d-%H%M')}.xlsx",
                                                                 type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
  end
end
