module Ti
  module Solicitacoes
    # Cria ou atualiza uma solicitação do catálogo, com auditoria.
    class Salvar
      CAMPOS = %i[categoria_id nome descricao prioridade_padrao exige_triagem permite_varios_abertos].freeze

      def self.call(...) = new(...).call

      def initialize(solicitacao:, atributos:, salvo_por:)
        @solicitacao = solicitacao
        @atributos = atributos.to_h.symbolize_keys.slice(*CAMPOS)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @solicitacao)
        end

        nova = @solicitacao.new_record?
        return Core::Resultado.falha(@solicitacao) unless @solicitacao.update(@atributos)

        mudancas = @solicitacao.saved_changes.except("id", "created_at", "updated_at").transform_values { |de, para| { de: de, para: para } }
        if mudancas.any?
          Core::Api.auditar(evento: "ti.solicitacao.#{nova ? 'criada' : 'atualizada'}", alvo: @solicitacao, ator: @salvo_por,
                            dados: (nova ? { nome: @solicitacao.nome } : { mudancas: mudancas }))
        end
        Core::Resultado.sucesso(@solicitacao)
      end
    end
  end
end
