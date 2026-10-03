module Core
  module Notificacoes
    # Cria uma notificação para cada destinatário (menos para quem fez a ação) e
    # avisa em tempo real (sino e aviso flutuante).
    #
    #   Core::Notificacoes::Criar.call(destinatarios: user, evento: "core.acesso.papel_concedido",
    #                                  titulo: "Você recebeu um novo papel", mensagem: "...", url_acao: "/")
    class Criar
      def self.call(...) = new(...).call

      # evento: "<modulo>.<objeto>.<acao>"
      def initialize(destinatarios:, evento:, titulo:, mensagem: nil, url_acao: nil, alvo: nil, ator: :contexto, dados: {})
        @destinatarios = Array(destinatarios).compact.uniq
        @modulo, @evento = evento.to_s.split(".", 2)
        @titulo = titulo
        @mensagem = mensagem
        @url_acao = url_acao
        @alvo = alvo
        @ator = ator == :contexto ? Core::Contexto.ator : ator
        @dados = dados || {}
      end

      def call
        @destinatarios.filter_map do |destinatario|
          next if @ator && destinatario.id == @ator.id
          next unless destinatario.ativo?

          notificacao = Core::Notificacao.create!(
            user: destinatario, ator: @ator, modulo: @modulo, evento: @evento, titulo: @titulo, mensagem: @mensagem,
            url_acao: @url_acao, alvo_tipo: @alvo&.class&.name, alvo_id: @alvo&.id, dados: @dados
          )
          Transmitir.nova(notificacao)
          EnviarPushJob.perform_later(notificacao) if Push.ativo?
          notificacao
        end
      end
    end
  end
end
