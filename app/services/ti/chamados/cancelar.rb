module Ti
  module Chamados
    # O solicitante desiste do chamado enquanto ele ainda está aberto ou esperando um ajuste dele.
    class Cancelar
      def self.call(...) = new(...).call

      def initialize(chamado:, user:, motivo:)
        @chamado = chamado
        @user = user
        @motivo = motivo.to_s.strip.presence
      end

      def call
        unless @chamado.solicitante_id == @user.id && @chamado.cancelavel_pelo_solicitante?
          return Core::Resultado.falha("Este chamado não pode mais ser cancelado por você. Fale com a TI pelo chamado.", objeto: @chamado)
        end
        return Core::Resultado.falha("Motivo deve ser preenchido.", objeto: @chamado) unless @motivo

        de = @chamado.status
        Ti::Chamado.transaction do
          @chamado.update!(status: "cancelado", finalizado_em: Time.current)
          @chamado.eventos.create!(tipo: "cancelado", de_status: de, para_status: "cancelado", nota: "Chamado cancelado pelo solicitante: #{@motivo}",
                                   ator: @user, ator_nome: @user.nome, ocorrido_em: Time.current)
          Core::Api.auditar(evento: "ti.chamado.cancelado", alvo: @chamado, ator: @user, dados: { codigo: @chamado.codigo, motivo: @motivo })
        end
        Conversa.sincronizar(@chamado, nota: "Chamado cancelado pelo solicitante: #{@motivo}")
        Avisos.notificar([ @chamado.responsavel, @chamado.triador ], @chamado, @user, "operacao", "Chamado cancelado pelo solicitante",
                         "#{@chamado.codigo} foi cancelado. #{@motivo}")
        Avisos.atualizar_telas(@chamado)
        Core::Resultado.sucesso(@chamado)
      end
    end
  end
end
