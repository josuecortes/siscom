module Transporte
  module Solicitacoes
    # O solicitante responde ao reagendamento proposto pela operação (regra do siscom antigo):
    # aceita (a solicitação volta a ficar aprovada, com o novo horário) ou recusa, com motivo
    # (os horários antigos voltam e a solicitação é cancelada; o histórico guarda o horário original e
    # o que a operação tentou marcar).
    class ResponderReagendamento
      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, aceitar:, motivo: nil)
        @solicitacao = solicitacao
        @ator = ator
        @aceitar = aceitar
        @motivo = motivo.to_s.strip.presence
      end

      def call
        return falha("Só quem pediu o transporte responde ao reagendamento.") unless @solicitacao.solicitante_id == @ator.id
        return falha("Não há reagendamento aguardando resposta nesta solicitação.") unless @solicitacao.reagendada?
        return falha("Motivo deve ser preenchido.") unless @aceitar || @motivo

        Transporte::Solicitacao.transaction { @aceitar ? aceitar : recusar }
        Avisos.notificar([ @solicitacao.reagendada_por ] + Avisos.operacao.to_a, @solicitacao, @ator, :operacao, titulo_do_aviso, mensagem_do_aviso)
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def aceitar
        @solicitacao.update!(status: "aprovada", reagendamento_respondido_em: Time.current)
        @solicitacao.registrar_evento("reagendamento_aceito", @ator, "Nova saída em #{I18n.l(@solicitacao.saida_em, format: Reagendar::FORMATO)}.")
        Core::Api.auditar(evento: "transporte.solicitacao.reagendamento_aceito", alvo: @solicitacao, ator: @ator, dados: { codigo: @solicitacao.codigo })
      end

      def recusar
        horarios = horarios_recusados
        @solicitacao.update!(status: "cancelada", saida_em: @solicitacao.saida_anterior_em || @solicitacao.saida_em,
                             retorno_em: @solicitacao.retorno_anterior_em || @solicitacao.retorno_em,
                             motivo_recusa_reagendamento: @motivo, reagendamento_respondido_em: Time.current,
                             cancelada_por: @ator, cancelada_em: Time.current, motivo_cancelamento: "Reagendamento recusado pelo solicitante: #{@motivo}")
        @solicitacao.registrar_evento("reagendamento_recusado", @ator, "#{horarios} Motivo: #{@motivo.delete_suffix('.')}. A solicitação foi cancelada.")
        Core::Api.auditar(evento: "transporte.solicitacao.reagendamento_recusado", alvo: @solicitacao, ator: @ator,
                          dados: { codigo: @solicitacao.codigo, motivo: @motivo })
      end

      # "Saída original: ...; saída proposta e recusada: ...." (e o retorno, quando mudou).
      def horarios_recusados
        formato = Reagendar::FORMATO
        s = @solicitacao
        partes = []
        if s.saida_anterior_em && s.saida_anterior_em != s.saida_em
          partes << "Saída original: #{I18n.l(s.saida_anterior_em, format: formato)}; saída proposta e recusada: #{I18n.l(s.saida_em, format: formato)}."
        end
        if s.retorno_anterior_em && s.retorno_anterior_em != s.retorno_em
          partes << "Retorno original: #{I18n.l(s.retorno_anterior_em, format: formato)}; retorno proposto e recusado: #{I18n.l(s.retorno_em, format: formato)}."
        end
        partes.join(" ")
      end

      def titulo_do_aviso = @aceitar ? "Reagendamento aceito" : "Reagendamento recusado"

      def mensagem_do_aviso
        return "#{@solicitacao.codigo}: #{@ator.nome} aceitou a nova saída." if @aceitar

        "#{@solicitacao.codigo}: #{@ator.nome} recusou o novo horário e a solicitação foi cancelada. #{@motivo}"
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
