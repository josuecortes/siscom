module Equipamentos
  module Envios
    # Notificações e atualização das telas abertas depois de uma mudança num envio.
    module Avisos
      module_function

      def notificar(destinatarios, envio, ator, evento, titulo, mensagem, url: nil)
        destinatarios = Array(destinatarios).flatten.compact.uniq - [ ator ]
        return if destinatarios.empty?

        Core::Api.notificar(destinatarios: destinatarios, evento: "equipamentos.envio.#{evento}", titulo: titulo, mensagem: mensagem.to_s.squish,
                            url_acao: url || Rails.application.routes.url_helpers.equipamentos_recebimentos_path, alvo: envio, ator: ator)
      end

      # Quem está com a lista do módulo ou com "Meus equipamentos" aberto vê a mudança na hora.
      def atualizar_telas(envio)
        ([ "equipamentos" ] + [ envio.responsavel, envio.criada_por ].compact.uniq.map { |user| [ user, "equipamentos" ] }).each do |canal|
          Turbo::StreamsChannel.broadcast_refresh_to(*Array(canal), request_id: nil)
        end
      end
    end
  end
end
