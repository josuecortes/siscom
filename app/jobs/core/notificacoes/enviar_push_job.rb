module Core
  module Notificacoes
    # Envia a notificação por push em segundo plano (Solid Queue).
    class EnviarPushJob < ApplicationJob
      queue_as :default
      discard_on ActiveJob::DeserializationError

      def perform(notificacao)
        return if notificacao.lida?

        Push.enviar(notificacao)
      end
    end
  end
end
