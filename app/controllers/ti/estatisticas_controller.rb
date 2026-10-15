module Ti
  # TI → Administração → Relatórios (porta da tela "Estatísticas" do siscom antigo): os chamados de um período por mês,
  # categoria, solicitação, unidade e técnico, com exportação para Excel.
  class EstatisticasController < BaseController
    before_action { pode!("ti.relatorios.ver") }

    def show
      @filtros = params.permit(:inicio, :fim, :categoria_id, :tecnico_id).to_h.symbolize_keys
      @estatisticas = Ti::Estatisticas::Consultar.call(filtros: @filtros)
      return unless params[:format] == "xlsx"

      Core::Api.auditar(evento: "ti.estatisticas.exportadas", dados: { inicio: @estatisticas.inicio, fim: @estatisticas.fim }, ator: current_user)
      send_data Ti::Estatisticas::Planilha.gerar(@estatisticas), filename: "ti-relatorio-#{Time.current.strftime('%Y%m%d-%H%M')}.xlsx",
                                                                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    # Técnicos que têm (ou tiveram) chamados, para o campo de busca do filtro (JSON).
    def tecnicos
      todos = ::User.where(id: Ti::Chamado.where.not(responsavel_id: nil).select(:responsavel_id)).order(:nome, :id)
      termo = params[:q].to_s.squish
      achados = termo.length >= 3 ? todos.buscar(termo) : todos.none
      nenhum = achados.none?
      escolhidos = nenhum ? todos : achados

      render json: { opcoes: escolhidos.limit(50).map { |user| { valor: user.id, rotulo: user.nome, subtitulo: user.email } }, todas: nenhum, restantes: [ escolhidos.count - 50, 0 ].max }
    end
  end
end
