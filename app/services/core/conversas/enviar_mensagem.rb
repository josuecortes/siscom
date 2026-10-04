module Core
  module Conversas
    # Grava uma mensagem, mostra em tempo real para quem está com a conversa aberta e notifica os
    # outros participantes (só na primeira mensagem ainda não lida de cada um, para não encher o sino).
    class EnviarMensagem
      def self.call(...) = new(...).call

      def self.do_sistema(conversa, texto)
        mensagem = conversa.mensagens.create!(tipo: "sistema", corpo: texto)
        transmitir(conversa, mensagem)
        mensagem
      end

      def self.transmitir(conversa, mensagem)
        conversa.update_column(:ultima_mensagem_em, mensagem.created_at)
        Turbo::StreamsChannel.broadcast_append_to(conversa, target: "mensagens_da_conversa_#{conversa.id}", partial: "core/conversas/mensagem",
                                                            locals: { mensagem: mensagem })
      end

      def initialize(conversa:, autor:, corpo:)
        @conversa = conversa
        @autor = autor
        @corpo = corpo
      end

      def call
        participante = @conversa.participante(@autor)
        unless @conversa.ativa? && participante&.pode_escrever?
          return Core::Resultado.falha("Esta conversa está só para leitura.")
        end

        mensagem = @conversa.mensagens.new(autor: @autor, autor_nome: @autor.nome, corpo: @corpo)
        return Core::Resultado.falha(mensagem) unless mensagem.save

        participante.update_column(:lida_ate_id, mensagem.id)
        self.class.transmitir(@conversa, mensagem)
        avisar(mensagem)
        Core::Resultado.sucesso(mensagem)
      end

      private

      def avisar(mensagem)
        @conversa.participantes.leitores.where.not(user_id: @autor.id).includes(:user).find_each do |participante|
          next unless participante.nao_lidas == 1

          Core::Notificacoes::Criar.call(destinatarios: participante.user, evento: "#{@conversa.modulo}.conversa.mensagem", ator: @autor,
                                         titulo: "Nova mensagem de #{@autor.nome}", mensagem: "#{@conversa.titulo}: #{mensagem.corpo.truncate(120)}",
                                         url_acao: participante.url || Rails.application.routes.url_helpers.conversa_path(@conversa), alvo: @conversa)
        end
      end
    end
  end
end
