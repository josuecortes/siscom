module Core
  # Minha área → Notificações (porta de platform-notifications-module.tsx e do sino).
  class NotificacoesController < ApplicationController
    POR_PAGINA = 20

    def index
      @busca = params[:q].to_s.strip
      notificacoes = current_user.notificacoes.recentes.includes(:ator)
      notificacoes = notificacoes.buscar(@busca) if @busca.present?

      @nao_lidas = current_user.notificacoes.nao_lidas.count
      @pagy, @notificacoes = pagy(:offset, notificacoes, limit: POR_PAGINA)
    end

    # Marca como lida e leva para a tela da notificação (quando houver).
    def abrir
      notificacao = current_user.notificacoes.find(params[:id])
      Notificacoes::MarcarLidas.uma(notificacao)

      redirect_to destino_de(notificacao), status: :see_other
    end

    def marcar_todas
      Notificacoes::MarcarLidas.todas(current_user)

      redirect_back_or_to notificacoes_path, status: :see_other
    end

    private

    # Só caminhos internos ("/..."), nunca endereços de fora.
    def destino_de(notificacao)
      url = notificacao.url_acao.to_s
      url.match?(%r{\A/(?!/)}) ? url : notificacoes_path
    end
  end
end
