module Core
  module Conversas
    # Cria ou atualiza a conversa de um registro (porta de sync_helpdesk_ticket_service.rb do seed):
    # define se está ativa, quem participa agora (quem saiu perde leitura e escrita) e, se houver,
    # acrescenta uma mensagem do sistema.
    #
    #   participantes: [{ user:, papel: "solicitante", url: "/ti/chamados/1" }, ...]
    class Sincronizar
      def self.call(...) = new(...).call

      def initialize(alvo:, modulo:, titulo:, ativa:, participantes:, motivo_leitura: nil, nota_do_sistema: nil)
        @alvo = alvo
        @modulo = modulo.to_s
        @titulo = titulo
        @ativa = ativa
        @participantes = participantes.select { |participante| participante[:user] }
        @motivo_leitura = motivo_leitura
        @nota = nota_do_sistema.to_s.squish.presence
      end

      def call
        Core::Conversa.transaction do
          conversa = Core::Conversa.find_or_initialize_by(alvo_tipo: @alvo.class.name, alvo_id: @alvo.id)
          conversa.update!(modulo: @modulo, titulo: @titulo, status: (@ativa ? "ativa" : "somente_leitura"), motivo_leitura: (@ativa ? nil : @motivo_leitura))
          atuais = @participantes.map { |participante| atualizar(conversa, participante) }
          encerrar_os_demais(conversa, atuais)
          EnviarMensagem.do_sistema(conversa, @nota) if @nota
          conversa
        end
      end

      private

      def atualizar(conversa, dados)
        participante = conversa.participantes.find_or_initialize_by(user: dados[:user])
        participante.update!(papel: dados.fetch(:papel, "participante"), url: dados[:url], pode_ler: true, pode_escrever: @ativa,
                             entrou_em: participante.entrou_em || Time.current, saiu_em: nil)
        participante.user_id
      end

      # Com a conversa ativa, quem deixou de participar não lê mais; encerrada, todos que passaram por ela leem o histórico.
      def encerrar_os_demais(conversa, atuais)
        conversa.participantes.where.not(user_id: atuais).find_each do |participante|
          participante.update!(pode_ler: !@ativa, pode_escrever: false, saiu_em: participante.saiu_em || Time.current)
        end
      end
    end
  end
end
