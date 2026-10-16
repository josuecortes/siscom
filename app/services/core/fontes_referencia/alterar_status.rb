module Core
  module FontesReferencia
    # Ativa ou desativa uma fonte (fonte inativa some das consultas).
    class AlterarStatus
      def self.call(...) = new(...).call

      def initialize(fonte:, ativo:, alterado_por:)
        @fonte = fonte
        @status = ativo ? "ativo" : "inativo"
        @alterado_por = alterado_por
      end

      def call
        unless Core::Autorizacao.new(@alterado_por).pode?(Salvar::PERMISSAO)
          return Core::Resultado.falha("Você não pode gerenciar fontes de referência.", objeto: @fonte)
        end
        return Core::Resultado.sucesso(@fonte) if @fonte.status == @status

        @fonte.update!(status: @status)
        Core::Auditoria::Registrar.call(evento: "core.fonte_referencia.#{@status == 'ativo' ? 'ativada' : 'desativada'}",
                                        alvo: @fonte, ator: @alterado_por)
        Core::Resultado.sucesso(@fonte)
      end
    end
  end
end
