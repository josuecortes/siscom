module Ti
  module Catalogo
    # Cria ou atualiza um item simples do catálogo da TI, com auditoria.
    class Salvar
      CAMPOS = %i[nome descricao permite_autoatribuicao].freeze

      def self.call(...) = new(...).call

      def initialize(registro:, atributos:, salvo_por:)
        @registro = registro
        @atributos = atributos.to_h.symbolize_keys.slice(*CAMPOS).select { |campo, _| registro.has_attribute?(campo) }
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @registro)
        end

        novo = @registro.new_record?
        return Core::Resultado.falha(@registro) unless @registro.update(@atributos)

        mudancas = @registro.saved_changes.except("id", "created_at", "updated_at").transform_values { |de, para| { de: de, para: para } }
        if mudancas.any?
          Core::Api.auditar(evento: "ti.catalogo.#{novo ? 'criado' : 'atualizado'}", alvo: @registro, ator: @salvo_por,
                            dados: { tabela: @registro.class.table_name, mudancas: (novo ? nil : mudancas) }.compact)
        end
        Core::Resultado.sucesso(@registro)
      end
    end
  end
end
