module Core
  module Conversas
    # Grava uma mensagem, mostra em tempo real para quem está com a conversa aberta e atualiza o
    # contador de não lidas no ícone flutuante dos outros participantes (não vai para o sino).
    class EnviarMensagem
      def self.call(...) = new(...).call

      def self.do_sistema(conversa, texto)
        mensagem = conversa.mensagens.create!(tipo: "sistema", corpo: texto)
        transmitir(conversa, mensagem)
        mensagem
      end

      # Atualiza o número sobre o ícone flutuante do usuário, onde quer que ele esteja no sistema.
      def self.atualizar_contador(user)
        Turbo::StreamsChannel.broadcast_replace_to(user, :conversas, target: "contador_de_conversas", partial: "core/conversas/contador",
                                                                     locals: { total: Core::Participante.nao_lidas_de(user) })
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

      def avisar(_mensagem)
        @conversa.participantes.leitores.where.not(user_id: @autor.id).includes(:user).find_each do |participante|
          self.class.atualizar_contador(participante.user)
        end
      end
    end
  end
end
