module Transporte
  module Solicitacoes
    # Cancela a solicitação, com motivo (porta de requests/cancel_service.rb do seed): a operação
    # cancela enquanto não terminou; o solicitante, só antes de o serviço começar.
    class Cancelar
      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, motivo:)
        @solicitacao = solicitacao
        @ator = ator
        @motivo = motivo.to_s.strip.presence
      end

      def call
        return falha("Você não pode cancelar esta solicitação.") unless da_operacao? || do_solicitante?
        return falha("Esta solicitação já terminou e não pode ser cancelada.") if @solicitacao.concluida? || @solicitacao.cancelada?
        unless da_operacao? || @solicitacao.antes_do_servico?
          return falha("O serviço já começou: só o setor de transporte pode cancelar agora.")
        end
        return falha("Motivo deve ser preenchido.") unless @motivo

        Transporte::Solicitacao.transaction do
          @solicitacao.update!(status: "cancelada", cancelada_por: @ator, cancelada_em: Time.current, motivo_cancelamento: @motivo)
          @solicitacao.registrar_evento("cancelada", @ator, "Motivo: #{@motivo}")
          Core::Api.auditar(evento: "transporte.solicitacao.cancelada", alvo: @solicitacao, ator: @ator, dados: { codigo: @solicitacao.codigo, motivo: @motivo })
        end
        avisar
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def da_operacao? = Core::Autorizacao.new(@ator).pode?(Aprovar::PERMISSAO)
      def do_solicitante? = @solicitacao.solicitante_id == @ator.id

      def avisar
        if do_solicitante? && !da_operacao?
          Avisos.notificar(Avisos.operacao.to_a, @solicitacao, @ator, :operacao, "Solicitação de transporte cancelada pelo solicitante", "#{@solicitacao.codigo}: #{@motivo}")
        else
          Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Solicitação de transporte cancelada", "#{@solicitacao.codigo}: #{@motivo}")
        end
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
