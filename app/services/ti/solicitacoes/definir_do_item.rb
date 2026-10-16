module Ti
  module Solicitacoes
    # Caminho inverso de DefinirVinculos: deixa um perfil de abertura (ou um grupo técnico)
    # exatamente com as solicitações informadas. Solicitações inativas não são mexidas.
    class DefinirDoItem
      def self.call(...) = new(...).call

      def initialize(item:, ids:, definido_por:)
        @item = item
        @ids = Array(ids).map(&:to_i).select(&:positive?).uniq
        @definido_por = definido_por
      end

      def call
        unless Core::Autorizacao.new(@definido_por).pode?(Ti::Catalogo::PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar o catálogo da TI.", objeto: @item)
        end

        ativas = Ti::Problema.ativo.pluck(:id)
        vinculos = @item.vinculos_de_problema
        atuais = vinculos.where(problema_id: ativas).pluck(:problema_id)
        entram = (ativas & @ids) - atuais
        saem = atuais - @ids

        @item.transaction do
          vinculos.where(problema_id: saem).destroy_all
          entram.each { |id| vinculos.create!(problema_id: id) }
        end

        if entram.any? || saem.any?
          Core::Api.auditar(evento: "ti.catalogo.solicitacoes_alteradas", alvo: @item, ator: @definido_por,
                            dados: { tabela: @item.class.table_name, entraram: entram, sairam: saem })
        end
        Core::Resultado.sucesso(@item)
      end
    end
  end
end
