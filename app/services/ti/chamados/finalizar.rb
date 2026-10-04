module Ti
  module Chamados
    # O solicitante encerra o chamado concluído, dizendo se resolveu e avaliando o atendimento
    # (como no siscom antigo: comentário obrigatório quando a avaliação é Ruim ou Péssimo).
    class Finalizar
      def self.call(...) = new(...).call

      def initialize(chamado:, user:, resolvido:, avaliacao:, comentario: nil)
        @chamado = chamado
        @user = user
        @resolvido = { "sim" => true, "nao" => false }[resolvido.to_s]
        @avaliacao = avaliacao.to_i
        @comentario = comentario.to_s.strip.presence
      end

      def call
        return falha("Este chamado não está aguardando a sua finalização.") unless @chamado.solicitante_id == @user.id && @chamado.concluido?

        erros = []
        erros << "Informe se o atendimento resolveu o seu pedido." if @resolvido.nil?
        erros << "Escolha uma avaliação." unless Ti::Chamado::AVALIACOES.key?(@avaliacao)
        erros << "Conte o que houve: o comentário é obrigatório quando a avaliação é Ruim ou Péssimo." if @avaliacao.between?(1, 2) && @comentario.nil?
        return falha(erros) if erros.any?

        @chamado.assign_attributes(status: "finalizado", finalizado_em: Time.current, avaliacao_resolvido: @resolvido, avaliacao: @avaliacao,
                                   avaliacao_comentario: @comentario)
        nota = "Chamado finalizado pelo solicitante. #{@resolvido ? 'O atendimento resolveu o pedido.' : 'O atendimento não resolveu o pedido.'} " \
               "Avaliação: #{@chamado.nome_da_avaliacao}."
        Ti::Chamado.transaction do
          @chamado.save!
          @chamado.eventos.create!(tipo: "finalizado", de_status: "concluido", para_status: "finalizado", nota: nota, ator: @user, ator_nome: @user.nome,
                                   ocorrido_em: @chamado.finalizado_em)
          Core::Api.auditar(evento: "ti.chamado.finalizado", alvo: @chamado, ator: @user,
                            dados: { codigo: @chamado.codigo, resolvido: @resolvido, avaliacao: @avaliacao })
        end
        Conversa.sincronizar(@chamado, nota: "Chamado finalizado pelo solicitante. Avaliação: #{@chamado.nome_da_avaliacao}.")
        Avisos.notificar([ @chamado.responsavel, @chamado.triador ], @chamado, @user, "operacao", "Chamado finalizado pelo solicitante",
                         "#{@chamado.codigo} foi encerrado. Avaliação: #{@chamado.nome_da_avaliacao}.")
        Avisos.atualizar_telas(@chamado)
        Core::Resultado.sucesso(@chamado)
      end

      private

      def falha(erros) = Core::Resultado.falha(erros, objeto: @chamado)
    end
  end
end
