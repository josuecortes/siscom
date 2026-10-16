module Ti
  module Catalogo
    # Ativa ou desativa um item do catálogo (item inativo some das opções, mas fica no histórico).
    class AlterarStatus
      def self.call(...) = new(...).call

      def initialize(registro:, ativo:, alterado_por:)
        @registro = registro
        @status = ativo ? "ativo" : "inativo"
        @alterado_por = alterado_por
      end

      def call
        unless Core::Autorizacao.new(@alterado_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @registro)
        end
        return Core::Resultado.sucesso(@registro) if @registro.status == @status

        @registro.update!(status: @status)
        Core::Api.auditar(evento: "ti.catalogo.#{@status == 'ativo' ? 'ativado' : 'desativado'}", alvo: @registro, ator: @alterado_por,
                          dados: { tabela: @registro.class.table_name })
        Core::Resultado.sucesso(@registro)
      end
    end
  end
end
