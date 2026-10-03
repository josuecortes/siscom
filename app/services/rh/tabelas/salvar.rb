module Rh
  module Tabelas
    # Cria ou atualiza um item de tabela de referência do RH, com auditoria.
    class Salvar
      PERMISSAO = "rh.tabelas.gerenciar".freeze

      def self.call(...) = new(...).call

      def initialize(registro:, atributos:, salvo_por:)
        @registro = registro
        @atributos = atributos.to_h.symbolize_keys.slice(:nome, :descricao)
        @atributos.delete(:descricao) unless registro.has_attribute?(:descricao)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar as tabelas de referência.", objeto: @registro)
        end

        novo = @registro.new_record?
        return Core::Resultado.falha(@registro) unless @registro.update(@atributos)

        mudancas = @registro.saved_changes.slice("nome", "descricao").transform_values { |de, para| { de: de, para: para } }
        if mudancas.any?
          Core::Api.auditar(evento: "rh.tabela.#{novo ? 'criada' : 'atualizada'}", alvo: @registro, ator: @salvo_por,
                            dados: { tabela: @registro.class.table_name, mudancas: (novo ? nil : mudancas) }.compact)
        end
        Core::Resultado.sucesso(@registro)
      end
    end
  end
end
