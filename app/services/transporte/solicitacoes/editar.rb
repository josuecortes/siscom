module Transporte
  module Solicitacoes
    # O solicitante corrige a própria solicitação enquanto ela está "solicitada" (porta de
    # requests/update_service.rb do seed). Depois de aprovada não dá mais: aí é reagendamento.
    #
    # As regras são as mesmas da abertura: os dados novos são conferidos num rascunho e só então
    # passam para a solicitação. Em falha, `objeto` é o rascunho com os erros.
    class Editar < Abrir
      def initialize(solicitacao:, ator:, atributos:)
        super(user: solicitacao.solicitante, atributos: atributos)
        @original = solicitacao
        @ator = ator
        @fora_do_padrao = solicitacao.fora_do_padrao?
      end

      def call
        return Core::Resultado.falha("Só quem pediu o transporte pode editar a solicitação.", objeto: @original) unless @original.solicitante_id == @ator.id
        unless @original.solicitada?
          return Core::Resultado.falha("A solicitação só pode ser editada enquanto está solicitada. Depois de aprovada, procure o setor de transporte.", objeto: @original)
        end

        super
      end

      private

      def conferir_documento
        super if @dados[:documento_da_viagem].respond_to?(:original_filename) || !@original.documento_da_viagem.attached?
      end

      def gravar
        rascunho = @solicitacao
        Transporte::Solicitacao.transaction do
          @original.update!(rascunho.attributes.slice("tipo", "modo", "resumo", "saida_em", "retorno_em", "espera_horas", "busca_horas", "rh_unidade_id", "unidade_nome"))
          @original.passageiros.destroy_all
          @original.destinos.destroy_all
          rascunho.passageiros.each { |item| @original.passageiros.create!(item.attributes.except("id", "solicitacao_id", "created_at", "updated_at")) }
          rascunho.destinos.each { |item| @original.destinos.create!(item.attributes.except("id", "solicitacao_id", "created_at", "updated_at")) }
          arquivo = @dados[:documento_da_viagem]
          @original.documento_da_viagem.attach(arquivo) if @original.viagem? && arquivo.respond_to?(:original_filename)
          @original.registrar_evento("editada", @ator, "Saída em #{I18n.l(@original.saida_em, format: Reagendar::FORMATO)}.")
          Core::Api.auditar(evento: "transporte.solicitacao.editada", alvo: @original, ator: @ator, dados: { codigo: @original.codigo })
        end
        @solicitacao = @original.reload
      end

      def avisar
        Avisos.notificar(Avisos.operacao.to_a, @solicitacao, @ator, :operacao, "Solicitação de transporte editada",
                         "#{@solicitacao.codigo}: #{@ator.nome} alterou o pedido. Saída em #{I18n.l(@solicitacao.saida_em, format: Reagendar::FORMATO)}.")
        Avisos.atualizar_telas(@solicitacao)
      end
    end
  end
end
