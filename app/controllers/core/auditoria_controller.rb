module Core
  # Administração → Auditoria: consulta dos registros (somente leitura).
  class AuditoriaController < BaseController
    POR_PAGINA = 30

    before_action { pode!("core.auditoria.ver") }

    def index
      @filtros = {
        q: params[:q].to_s.strip,
        evento: params[:evento].presence_in(eventos_conhecidos.map(&:last)),
        de: data(params[:de]),
        ate: data(params[:ate])
      }

      registros = Core::RegistroAuditoria.recentes.entre(@filtros[:de], @filtros[:ate])
      registros = registros.buscar(@filtros[:q]) if @filtros[:q].present?
      if @filtros[:evento]
        modulo, evento = @filtros[:evento].split(".", 2)
        registros = registros.do_modulo(modulo).do_evento(evento)
      end

      @eventos = eventos_conhecidos
      @pagy, @registros = pagy(:offset, registros, limit: POR_PAGINA)
    end

    private

    def data(texto)
      Date.iso8601(texto.to_s)
    rescue ArgumentError
      nil
    end

    # [["Usuário cadastrado", "core.usuario.criado"], ...] a partir dos rótulos traduzidos.
    def eventos_conhecidos
      @eventos_conhecidos ||= I18n.t("auditoria.eventos").flat_map do |modulo, objetos|
        objetos.flat_map { |objeto, acoes| acoes.map { |acao, rotulo| [ rotulo, "#{modulo}.#{objeto}.#{acao}" ] } }
      end.sort
    end
  end
end
