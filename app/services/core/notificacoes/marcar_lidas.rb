module Core
  module Notificacoes
    # Marca como lida uma notificação ou todas as do usuário, e atualiza o sino.
    module MarcarLidas
      module_function

      def uma(notificacao)
        return notificacao if notificacao.lida?

        notificacao.update!(lida_em: Time.current)
        Transmitir.sino(notificacao.user)
        notificacao
      end

      def todas(user)
        agora = Time.current
        total = Core::Notificacao.where(user: user).nao_lidas.update_all(lida_em: agora, updated_at: agora) # rubocop:disable Rails/SkipsModelValidations
        Transmitir.sino(user) if total.positive?
        total
      end
    end
  end
end
