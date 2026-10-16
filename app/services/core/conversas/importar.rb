module Core
  module Conversas
    # Importa a conversa antiga de um registro (migração do siscom antigo): conversa só para leitura,
    # mensagens nas datas originais e já marcadas como lidas, sem notificação nem aviso em tempo real.
    # Idempotente: se o registro já tem conversa, devolve a que existe.
    #
    # Mensagem maior que o limite é dividida em mais de uma (não se corta texto).
    class Importar
      def self.call(...) = new(...).call

      def initialize(alvo:, modulo:, titulo:, participantes:, mensagens:, motivo_leitura: nil)
        @alvo = alvo
        @modulo = modulo.to_s
        @titulo = titulo
        @participantes = participantes.select { |participante| participante[:user] }.uniq { |participante| participante[:user].id }
        @mensagens = mensagens.select { |mensagem| mensagem[:corpo].to_s.strip.present? }
        @motivo_leitura = motivo_leitura
      end

      def call
        existente = Core::Conversa.de(@alvo)
        return existente if existente || @mensagens.empty?

        Core::Conversa.transaction do
          conversa = Core::Conversa.create!(modulo: @modulo, alvo_tipo: @alvo.class.name, alvo_id: @alvo.id, titulo: @titulo, status: "somente_leitura",
                                            motivo_leitura: @motivo_leitura)
          ultima = @mensagens.flat_map { |mensagem| gravar(conversa, mensagem) }.last
          conversa.update!(ultima_mensagem_em: ultima.created_at)
          @participantes.each do |dados|
            conversa.participantes.create!(user: dados[:user], papel: dados.fetch(:papel, "participante"), url: dados[:url], pode_ler: true, pode_escrever: false,
                                           lida_ate_id: ultima.id, entrou_em: conversa.mensagens.minimum(:created_at))
          end
          conversa
        end
      end

      private

      def gravar(conversa, mensagem)
        mensagem[:corpo].to_s.strip.scan(/.{1,#{Core::Mensagem::TAMANHO_MAXIMO}}/m).map do |parte|
          conversa.mensagens.create!(autor: mensagem[:autor], autor_nome: mensagem[:autor]&.nome, tipo: "texto", corpo: parte, created_at: mensagem[:em], updated_at: mensagem[:em])
        end
      end
    end
  end
end
