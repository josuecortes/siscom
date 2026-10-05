module Transporte
  module Servicos
    # Fecha o trecho em andamento com o odômetro final (porta de requests/finish_service.rb do seed).
    # Ida de "buscar depois" → aguardando busca (com a hora prevista); nos outros casos → concluída.
    # Fecha o motorista do trecho, ou a operação.
    class Finalizar
      def self.call(...) = new(...).call

      def initialize(solicitacao:, ator:, odometro:)
        @solicitacao = solicitacao
        @ator = ator
        @odometro = Integer(odometro.to_s.delete("."), exception: false)
      end

      def call
        servico = @solicitacao.servico_aberto
        return falha("Não há serviço em andamento nesta solicitação.") unless servico
        unless servico.motorista_id == @ator.id || Core::Autorizacao.new(@ator).pode?(Solicitacoes::Aprovar::PERMISSAO)
          return falha("Só o motorista deste serviço ou a operação pode finalizá-lo.")
        end
        return falha("Odômetro final deve ser um número.") unless @odometro
        return falha("Odômetro final não pode ser menor que o inicial (#{servico.odometro_inicial} km).") if @odometro < servico.odometro_inicial

        Transporte::Servico.transaction do
          servico.update!(odometro_final: @odometro, finalizado_em: Time.current)
          servico.veiculo.update!(odometro_atual: [ servico.veiculo.odometro_atual, @odometro ].max)
          @solicitacao.update!(proximo_estado(servico))
          Core::Api.auditar(evento: "transporte.servico.finalizado", alvo: @solicitacao, ator: @ator,
                            dados: { codigo: @solicitacao.codigo, trecho: servico.trecho, placa: servico.placa, odometro: @odometro, km: servico.km_rodados })
        end
        avisar
        Solicitacoes::Avisos.atualizar_telas(@solicitacao)
        Core::Resultado.sucesso(@solicitacao)
      end

      private

      def proximo_estado(servico)
        if servico.de_ida? && @solicitacao.buscar_depois?
          { status: "busca", busca_prevista_em: Time.current + @solicitacao.busca_horas.to_i.hours, ultimo_aviso_de_busca_em: nil }
        else
          { status: "concluida", concluida_em: Time.current, busca_prevista_em: nil }
        end
      end

      def avisar
        if @solicitacao.busca?
          previsao = I18n.l(@solicitacao.busca_prevista_em, format: "%d/%m/%Y %H:%M")
          Solicitacoes::Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Você foi deixado no destino", "#{@solicitacao.codigo}: busca prevista para #{previsao}.")
          Solicitacoes::Avisos.notificar(Solicitacoes::Avisos.operacao.to_a, @solicitacao, @ator, :operacao, "Solicitação aguardando busca", "#{@solicitacao.codigo}: busca prevista para #{previsao}.")
        else
          Solicitacoes::Avisos.notificar(@solicitacao.solicitante, @solicitacao, @ator, :solicitante, "Transporte concluído", "#{@solicitacao.codigo} foi concluída.")
        end
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @solicitacao)
    end
  end
end
