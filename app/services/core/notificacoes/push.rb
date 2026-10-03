module Core
  module Notificacoes
    # Envio de notificação push (Web Push) para os aparelhos inscritos do usuário.
    module Push
      module_function

      def ativo? = Rails.configuration.x.push.ativo

      def chave_publica = Rails.configuration.x.push.chave_publica

      # Envia para todos os aparelhos do destinatário; remove inscrições vencidas.
      # Devolve quantos aparelhos receberam.
      def enviar(notificacao)
        return 0 unless ativo?

        corpo = { titulo: notificacao.titulo, mensagem: notificacao.mensagem.to_s.truncate(180),
                  url: "/minha-area/notificacoes", tag: "notificacao-#{notificacao.id}" }.to_json

        Core::InscricaoPush.where(user_id: notificacao.user_id).count { |inscricao| enviar_para(inscricao, corpo) }
      end

      def enviar_para(inscricao, corpo)
        WebPush.payload_send(
          message: corpo, endpoint: inscricao.endpoint, p256dh: inscricao.p256dh, auth: inscricao.auth, ttl: 1.day.to_i,
          vapid: { subject: Rails.configuration.x.push.contato, public_key: chave_publica,
                   private_key: Rails.configuration.x.push.chave_privada }
        )
        inscricao.update_column(:ultimo_envio_em, Time.current) # rubocop:disable Rails/SkipsModelValidations
        true
      rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
        inscricao.destroy
        false
      rescue WebPush::ResponseError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
        Rails.logger.warn("[push] falha ao enviar para a inscrição #{inscricao.id}: #{e.class}")
        false
      end
    end
  end
end
