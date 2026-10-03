module Rh
  module Unidades
    # Ativa ou desativa uma unidade. Não desativa unidade com lotações ativas.
    class AlterarStatus
      def self.call(...) = new(...).call

      def initialize(unidade:, ativo:, alterado_por:)
        @unidade = unidade
        @status = ativo ? "ativo" : "inativo"
        @alterado_por = alterado_por
      end

      def call
        return falha("Você não pode ativar ou desativar unidades.") unless Core::Autorizacao.new(@alterado_por).pode?(Salvar::PERMISSAO)
        return Core::Resultado.sucesso(@unidade) if @unidade.status == @status

        ativas = @unidade.lotacoes.ativo.count
        return falha("Esta unidade tem #{ativas} lotação(ões) ativa(s). Encerre ou mova as lotações antes de desativar.") if @status == "inativo" && ativas.positive?

        @unidade.update_column(:status, @status) # rubocop:disable Rails/SkipsModelValidations -- unidade antiga pode não ter sigla
        Core::Api.auditar(evento: "rh.unidade.#{@status == 'ativo' ? 'ativada' : 'desativada'}", alvo: @unidade, ator: @alterado_por)
        Core::Resultado.sucesso(@unidade)
      end

      private

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @unidade)
    end
  end
end
