module Transporte
  module Solicitacoes
    # A operação aprova a solicitação (porta de requests/approve_service.rb do seed).
    class Aprovar
      PERMISSAO = "transporte.solicitacoes.aprovar".freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:)
        @solicitacao = solicitacao
        @ator = ator
      end

      def call
        return falha("Você não pode aprovar solicitações de transporte.") unless Core::Autorizacao.new(@ator).pode?(PERMISSAO)
        return falha("Só dá para aprovar uma solicitação que ainda está como solicitada.") unless @solicitacao.solicitada?

        Transporte::Solicitacao.transaction do
          @solicitacao.update!(status: "aprovada", aprovada_por: @ator, aprovada_em: Time.current)
          Core::Api.auditar(evento: "transporte.solicitacao.aprovada", alvo: @solicitacao, ator: @ator, dados: { codigo: @solicitacao.codigo })
        end
        Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Solicitação de transporte aprovada",
                         "#{@solicitacao.codigo} foi aprovada. Saída em #{I18n.l(@solicitacao.saida_em, format: '%d/%m/%Y %H:%M')}.")
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
