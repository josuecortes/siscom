module Core
  module Notificacoes
    # Tempo real (Turbo Streams sobre Action Cable): atualiza o sino do usuário em
    # todas as abas abertas e, numa notificação nova, mostra o aviso flutuante.
    module Transmitir
      module_function

      def canal(user) = [ user, :notificacoes ]

      def nova(notificacao)
        sino(notificacao.user)
        Turbo::StreamsChannel.broadcast_append_to(
          canal(notificacao.user), target: "avisos",
          partial: "compartilhado/aviso", locals: { tipo: :notice, mensagem: notificacao.titulo }
        )
      end

      def sino(user)
        Turbo::StreamsChannel.broadcast_replace_to(
          canal(user), target: "sino_notificacoes",
          partial: "layouts/compartilhado/sino", locals: { user: user }
        )
      end
    end
  end
end
