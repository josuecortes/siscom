module Equipamentos
  # Equipamentos → Histórico: tudo o que aconteceu com os equipamentos que a pessoa enxerga (cadastro, cada
  # alteração com o antes e o depois, situação, kit, movimentações, empréstimos), pesquisável.
  class HistoricoController < BaseController
    POR_PAGINA = 30

    before_action { pode!("equipamentos.historico.ver") }

    def show
      @filtros = { q: params[:q].to_s.strip, tipo: params[:tipo].presence_in(Equipamentos::Evento::TIPOS.keys), de: DataBr.interpretar(params[:de]), ate: DataBr.interpretar(params[:ate]) }
      eventos = Equipamentos::Evento.where(item_id: Equipamentos::Acesso.itens_visiveis(current_user).select(:id))
      eventos = buscar(eventos, @filtros[:q]) if @filtros[:q].present?
      eventos = eventos.where(tipo: @filtros[:tipo]) if @filtros[:tipo]
      eventos = eventos.where(ocorrido_em: (@filtros[:de]&.in_time_zone&.beginning_of_day)..(@filtros[:ate]&.in_time_zone&.end_of_day)) if @filtros[:de] || @filtros[:ate]
      @pagy, @eventos = pagy(:offset, eventos.recentes.includes(:item), limit: POR_PAGINA)
    end

    private

    # Pelo que mudou (texto do registro), por quem fez, ou por qualquer dado do equipamento.
    def buscar(eventos, termo)
      padrao = "%#{Equipamentos::Evento.sanitize_sql_like(termo.squish.upcase)}%"
      eventos.where("UPPER(equipamentos_eventos.nota) LIKE :t OR UPPER(equipamentos_eventos.ator_nome) LIKE :t", t: padrao)
             .or(eventos.where(item_id: Equipamentos::Item.buscar(termo).select(:id)))
    end
  end
end
