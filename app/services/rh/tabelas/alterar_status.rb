module Rh
  module Tabelas
    # Ativa ou desativa um item de tabela de referência (item inativo some das opções dos formulários).
    class AlterarStatus
      def self.call(...) = new(...).call

      def initialize(registro:, ativo:, alterado_por:)
        @registro = registro
        @status = ativo ? "ativo" : "inativo"
        @alterado_por = alterado_por
      end

      def call
        unless Core::Autorizacao.new(@alterado_por).pode?(Salvar::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar as tabelas de referência.", objeto: @registro)
        end
        return Core::Resultado.sucesso(@registro) if @registro.status == @status

        @registro.update!(status: @status)
        Core::Api.auditar(evento: "rh.tabela.#{@status == 'ativo' ? 'ativada' : 'desativada'}", alvo: @registro, ator: @alterado_por,
                          dados: { tabela: @registro.class.table_name })
        Core::Resultado.sucesso(@registro)
      end
    end
  end
end
