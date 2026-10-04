module Ti
  module Chamados
    # O solicitante responde ao pedido de ajuste e o chamado volta para a operação: para o
    # responsável, se houver; senão para o triador; senão fica aberto de novo.
    class Responder
      def self.call(...) = new(...).call

      def initialize(chamado:, user:, nota:)
        @chamado = chamado
        @user = user
        @nota = nota.to_s.strip.presence
      end

      def call
        unless @chamado.solicitante_id == @user.id && @chamado.aguardando_solicitante?
          return Core::Resultado.falha("Este chamado não está aguardando a sua resposta.", objeto: @chamado)
        end
        return Core::Resultado.falha("Resposta deve ser preenchida.", objeto: @chamado) unless @nota

        de = @chamado.status
        @chamado.status = @chamado.responsavel_id ? "em_atendimento" : (@chamado.triador_id ? "em_triagem" : "aberto")
        Ti::Chamado.transaction do
          @chamado.save!
          @chamado.eventos.create!(tipo: "respondido", de_status: de, para_status: @chamado.status, nota: "Solicitante respondeu: #{@nota}",
                                   ator: @user, ator_nome: @user.nome, ocorrido_em: Time.current)
          Core::Api.auditar(evento: "ti.chamado.respondido", alvo: @chamado, ator: @user, dados: { codigo: @chamado.codigo })
        end
        Avisos.depois_de(@chamado, acao: "responder", de: de, ator: @user)
        Core::Resultado.sucesso(@chamado)
      end
    end
  end
end
