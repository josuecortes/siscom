module Core
  # Minha área → Conversas (porta de platform-conversations-module.tsx): as conversas de que o
  # usuário participa, com as não lidas.
  class ConversasController < ApplicationController
    POR_PAGINA = 20

    def index
      participacoes = current_user.participacoes_em_conversas.leitores.joins(:conversa).includes(:conversa)
                                  .order(Arel.sql("core_conversas.ultima_mensagem_em DESC NULLS LAST"), "core_conversas.id DESC")
      @pagy, @participacoes = pagy(:offset, participacoes, limit: POR_PAGINA)
    end

    def show
      @conversa = Core::Conversa.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @conversa.participante(current_user)&.pode_ler?
    end
  end
end
