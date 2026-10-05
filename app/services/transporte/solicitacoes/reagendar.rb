module Transporte
  module Solicitacoes
    # A operação muda a data e hora da saída (enquanto o serviço não começou), do retorno (viagem) e,
    # quando a solicitação está aguardando busca, a hora prevista da busca
    # (porta de requests/reschedule_service.rb do seed).
    class Reagendar
      PERMISSAO = "transporte.solicitacoes.operar".freeze

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
        return falha("Só dá para reagendar antes de o serviço começar, ou a busca enquanto ela é aguardada.") unless @solicitacao.solicitada? || @solicitacao.aprovada?
        return falha("Informe a nova saída ou o novo retorno.") if @saida.nil? && @retorno.nil?
        return falha("Motivo deve ser preenchido.") unless @motivo

        antes = { saida_em: @solicitacao.saida_em, retorno_em: @solicitacao.retorno_em }
        erro = aplicar
        return falha(erro) if erro
        return Core::Resultado.falha(@solicitacao.errors.full_messages, objeto: @solicitacao) unless @solicitacao.valid?

        Transporte::Solicitacao.transaction do
          @solicitacao.lembrete_enviado_em = nil
          @solicitacao.save!
          Core::Api.auditar(evento: "transporte.solicitacao.reagendada", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, de: antes, para: { saida_em: @solicitacao.saida_em, retorno_em: @solicitacao.retorno_em }, motivo: @motivo })
        end
        Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Solicitação de transporte reagendada",
                         "#{@solicitacao.codigo}: nova saída em #{I18n.l(@solicitacao.saida_em, format: '%d/%m/%Y %H:%M')}. #{@motivo}")
        Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def reagendar_busca
        busca = Abrir.data_e_hora(@busca)
        return falha("Busca deve ser uma data e hora válidas (dd/mm/aaaa hh:mm).") if busca.nil?
        return falha("Motivo deve ser preenchido.") unless @motivo

        antes = @solicitacao.busca_prevista_em
        @solicitacao.update!(busca_prevista_em: busca, ultimo_aviso_de_busca_em: nil)
        Core::Api.auditar(evento: "transporte.solicitacao.busca_reagendada", alvo: @solicitacao, ator: @ator,
                          dados: { codigo: @solicitacao.codigo, de: antes, para: busca, motivo: @motivo })
        Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Busca reagendada",
                         "#{@solicitacao.codigo}: busca prevista para #{I18n.l(busca, format: '%d/%m/%Y %H:%M')}. #{@motivo}")
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

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
