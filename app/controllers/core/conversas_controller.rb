module Core
  # Conversas do usuário (porta de chat-launcher.tsx e platform-conversations-module.tsx): o ícone
  # flutuante abre um painel com a lista (`lancador`) e, ao escolher, com a conversa (`painel`).
  # Minha área → Conversas mostra a mesma lista em página.
  class ConversasController < ApplicationController
    POR_PAGINA = 20

    def index
      @pagy, @participacoes = pagy(:offset, participacoes, limit: POR_PAGINA)
    end

    def lancador
      todas = participacoes.limit(50).to_a
      @ativas, @historico = todas.partition { |participacao| participacao.conversa.ativa? }
      @nao_lidas = Core::Participante.nao_lidas_de(current_user)
    end

    def painel
      @conversa = Core::Conversa.find(params[:id])
      @participante = participante!
      marcar_lida
    end

    # O navegador avisa que a pessoa está vendo a conversa (mensagem nova chegou com o painel aberto).
    def lida
      @conversa = Core::Conversa.find(params[:id])
      @participante = participante!
      marcar_lida
      head :no_content
    end

    private

    def participacoes
      current_user.participacoes_em_conversas.leitores.joins(:conversa).includes(:conversa)
                  .order(Arel.sql("core_conversas.ultima_mensagem_em DESC NULLS LAST"), "core_conversas.id DESC")
    end

    def participante!
      participante = @conversa.participante(current_user)
      raise ActiveRecord::RecordNotFound unless participante&.pode_ler?

      participante
    end

    def marcar_lida
      antes = @participante.lida_ate_id
      @participante.marcar_lida!
      Conversas::EnviarMensagem.atualizar_contador(current_user) if @participante.lida_ate_id != antes
    end
  end
end
