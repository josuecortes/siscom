module Equipamentos
  module Itens
    # Cadastra ou altera um equipamento. Toda alteração fica no histórico do equipamento, com quem mudou e o
    # antes e o depois de cada campo, e na auditoria. A unidade não muda aqui (só por movimentação recebida),
    # e equipamento em movimentação ou emprestado não pode ser alterado.
    class Salvar
      def self.call(...) = new(...).call

      def initialize(item:, atributos:, salvo_por:)
        @item = item
        @dados = atributos.to_h.symbolize_keys
        @salvo_por = salvo_por
      end

      def call
        novo = @item.new_record?
        return falha("Escolha a unidade do equipamento.") if novo && !definir_unidade
        return falha("Você não pode #{novo ? 'cadastrar equipamentos nesta unidade' : 'alterar este equipamento'}.") unless Acesso.pode_gerenciar?(@salvo_por, @item)
        return falha("Este equipamento está #{@item.nome_da_situacao.downcase} e não pode ser alterado agora.") unless novo || @item.disponivel?

        @item.assign_attributes(@dados.slice(*Equipamentos::Item::CAMPOS.keys))
        @item.cadastrado_por ||= @salvo_por
        return Core::Resultado.falha(@item) unless @item.valid?

        mudancas = @item.changes.slice(*Equipamentos::Item::CAMPOS.keys.map(&:to_s))
        Equipamentos::Item.transaction do
          @item.save!
          registrar(novo, mudancas)
        end
        Core::Resultado.sucesso(@item)
      end

      private

      def definir_unidade
        unidade = Rh::Api.unidade(@dados[:rh_unidade_id])
        @item.assign_attributes(rh_unidade_id: unidade.id, unidade_nome: unidade.sigla_e_nome) if unidade
        unidade.present?
      end

      def registrar(novo, mudancas)
        if novo
          @item.registrar_evento("cadastrado", @salvo_por, "Cadastrado em #{@item.unidade_nome}.")
          Core::Api.auditar(evento: "equipamentos.item.cadastrado", alvo: @item, ator: @salvo_por, dados: { identificacao: @item.identificacao, unidade: @item.unidade_nome })
        elsif mudancas.any?
          nota = mudancas.map { |campo, (de, para)| "#{Equipamentos::Item::CAMPOS[campo.to_sym]}: #{de.presence || 'vazio'} → #{para.presence || 'vazio'}" }.join("; ")
          @item.registrar_evento("editado", @salvo_por, nota, mudancas: mudancas)
          Core::Api.auditar(evento: "equipamentos.item.editado", alvo: @item, ator: @salvo_por, dados: { identificacao: @item.identificacao, mudancas: mudancas })
        end
      end

      def falha(mensagem)
        @item.errors.add(:base, mensagem)
        Core::Resultado.falha(mensagem, objeto: @item)
      end
    end
  end
end
