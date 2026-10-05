module Transporte
  module Solicitacoes
    # Notificações e atualização das telas abertas depois de uma mudança na solicitação.
    module Avisos
      module_function

      def operacao = ::User.ativos.where(id: Core::Api.ids_dos_usuarios_com_papel(modulo: :transporte, papeis: %w[admin tecnico]))

      def notificar(destinatarios, solicitacao, ator, lado, titulo, mensagem)
        destinatarios = Array(destinatarios).flatten.compact.uniq - [ ator ]
        return if destinatarios.empty?

        rotas = Rails.application.routes.url_helpers
        url = lado == :solicitante ? rotas.transporte_solicitacao_path(solicitacao) : rotas.transporte_operacao_path(solicitacao)
        Core::Api.notificar(destinatarios: destinatarios, evento: "transporte.solicitacao.#{solicitacao.status}", titulo: titulo, mensagem: mensagem.squish,
                            url_acao: url, alvo: solicitacao, ator: ator)
      end

      # Quem está com a operação, com a solicitação ou com a própria lista aberta vê a mudança na hora.
      # (Sem request_id: ver Ti::Chamados::Avisos.)
      def atualizar_telas(solicitacao)
        [ "transporte_operacao", solicitacao, [ solicitacao.solicitante, "transporte_solicitacoes" ] ].each do |canal|
          Turbo::StreamsChannel.broadcast_refresh_to(*Array(canal), request_id: nil)
        end
      end
    end
  end
end
