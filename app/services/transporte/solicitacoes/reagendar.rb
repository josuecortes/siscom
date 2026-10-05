module Transporte
  module Solicitacoes
    # A operação propõe outro horário para uma solicitação aprovada (regra do siscom antigo): informa o
    # motivo e a nova saída (e o novo retorno, na viagem). A solicitação fica "reagendada" até o
    # solicitante aceitar ou recusar (ResponderReagendamento).
    #
    # Quando a solicitação está aguardando busca, muda só a hora prevista da busca, sem aceite
    # (porta de requests/reschedule_service.rb do seed).
    class Reagendar
      PERMISSAO = "transporte.solicitacoes.operar".freeze
      FORMATO = "%d/%m/%Y %H:%M".freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, saida_em: nil, retorno_em: nil, busca_em: nil, motivo: nil)
        @solicitacao = solicitacao
        @ator = ator
        @saida = saida_em.presence
        @retorno = retorno_em.presence
        @busca = busca_em.presence
        @motivo = motivo.to_s.strip.presence
      end

      def call
        return falha("Você não pode reagendar solicitações de transporte.") unless Core::Autorizacao.new(@ator).pode?(PERMISSAO)
        return reagendar_busca if @solicitacao.busca?
        return falha("Esta solicitação já foi reagendada e aguarda a resposta do solicitante.") if @solicitacao.reagendada?
        return falha("Só dá para reagendar uma solicitação aprovada, antes de o serviço começar, ou a busca enquanto ela é aguardada.") unless @solicitacao.aprovada?
        return falha("Informe a nova saída ou o novo retorno.") if @saida.nil? && @retorno.nil?
        return falha("Motivo deve ser preenchido.") unless @motivo

        antes = { saida_em: @solicitacao.saida_em, retorno_em: @solicitacao.retorno_em }
        erro = aplicar
        return falha(erro) if erro
        return falha("Mude a saída ou o retorno para reagendar.") if antes == { saida_em: @solicitacao.saida_em, retorno_em: @solicitacao.retorno_em }
        return Core::Resultado.falha(@solicitacao.errors.full_messages, objeto: @solicitacao) unless @solicitacao.valid?

        gravar(antes)
        Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Reagendamento aguardando a sua resposta",
                         "#{@solicitacao.codigo}: nova saída em #{I18n.l(@solicitacao.saida_em, format: FORMATO)}. #{@motivo} Aceite ou recuse o novo horário.")
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def gravar(antes)
        Transporte::Solicitacao.transaction do
          @solicitacao.assign_attributes(status: "reagendada", saida_anterior_em: antes[:saida_em], retorno_anterior_em: antes[:retorno_em],
                                         motivo_reagendamento: @motivo, reagendada_por: @ator, reagendada_em: Time.current,
                                         motivo_recusa_reagendamento: nil, reagendamento_respondido_em: nil, lembrete_enviado_em: nil)
          @solicitacao.save!
          @solicitacao.registrar_evento("reagendada", @ator, "#{mudanca(antes)} Motivo: #{@motivo}")
          Core::Api.auditar(evento: "transporte.solicitacao.reagendada", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, de: antes, para: { saida_em: @solicitacao.saida_em, retorno_em: @solicitacao.retorno_em }, motivo: @motivo })
        end
      end

      def mudanca(antes)
        partes = []
        partes << "Saída de #{I18n.l(antes[:saida_em], format: FORMATO)} para #{I18n.l(@solicitacao.saida_em, format: FORMATO)}." if antes[:saida_em] != @solicitacao.saida_em
        if antes[:retorno_em] != @solicitacao.retorno_em
          partes << "Retorno de #{I18n.l(antes[:retorno_em], format: FORMATO)} para #{I18n.l(@solicitacao.retorno_em, format: FORMATO)}."
        end
        partes.join(" ")
      end

      def reagendar_busca
        busca = Abrir.data_e_hora(@busca)
        return falha("Busca deve ser uma data e hora válidas (dd/mm/aaaa hh:mm).") if busca.nil?
        return falha("Motivo deve ser preenchido.") unless @motivo

        antes = @solicitacao.busca_prevista_em
        Transporte::Solicitacao.transaction do
          @solicitacao.update!(busca_prevista_em: busca, ultimo_aviso_de_busca_em: nil)
          @solicitacao.registrar_evento("busca_reagendada", @ator, "Busca prevista para #{I18n.l(busca, format: FORMATO)}. Motivo: #{@motivo}")
          Core::Api.auditar(evento: "transporte.solicitacao.busca_reagendada", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, de: antes, para: busca, motivo: @motivo })
        end
        Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Busca reagendada",
                         "#{@solicitacao.codigo}: busca prevista para #{I18n.l(busca, format: FORMATO)}. #{@motivo}")
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      def aplicar
        if @saida
          saida = Abrir.data_e_hora(@saida)
          return "Saída deve ser uma data e hora válidas (dd/mm/aaaa hh:mm)." if saida.nil?
          return "Saída não pode estar no passado." if saida < Time.current

          @solicitacao.saida_em = saida
        end
        return nil unless @retorno
        return "Só a viagem tem retorno." unless @solicitacao.viagem?

        retorno = Abrir.data_e_hora(@retorno)
        return "Retorno deve ser uma data e hora válidas (dd/mm/aaaa hh:mm)." if retorno.nil?

        @solicitacao.retorno_em = retorno
        nil
      end

      def falha(mensagem)
        @solicitacao.restore_attributes
        Core::Resultado.falha(mensagem, objeto: @solicitacao)
      end
    end
  end
end
