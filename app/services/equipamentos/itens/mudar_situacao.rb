module Equipamentos
  module Itens
    # Muda a situação do equipamento (ativo, inativo, em manutenção, descartado), com motivo. É também o jeito de
    # tirar um equipamento de uso (descarte/baixa): ele deixa de poder ser movimentado, mas continua nas listas,
    # nos relatórios e com o histórico. Só o equipamento livre (fora de envio aberto) muda de situação.
    class MudarSituacao
      def self.call(...) = new(...).call

      def initialize(item:, status:, motivo:, ator:)
        @item = item
        @status = status.to_s
        @motivo = motivo.to_s.squish.presence
        @ator = ator
      end

      def call
        return falha("Você não pode alterar este equipamento.") unless Acesso.pode_gerenciar?(@ator, @item)
        return falha("Escolha a nova situação.") unless Equipamentos::Item::STATUS.key?(@status)
        return falha("O equipamento já está nessa situação.") if @status == @item.status
        return falha("Este equipamento está #{@item.nome_da_situacao.downcase} e não pode mudar de situação agora.") unless @item.disponivel?
        return falha("Motivo deve ser preenchido.") unless @motivo

        de = @item.nome_do_status
        Equipamentos::Item.transaction do
          @item.update!(status: @status)
          @item.registrar_evento("situacao_alterada", @ator, "De #{de} para #{@item.nome_do_status}. Motivo: #{@motivo}", mudancas: { "status" => [ de, @item.nome_do_status ] })
          Core::Api.auditar(evento: "equipamentos.item.situacao_alterada", alvo: @item, ator: @ator, dados: { identificacao: @item.identificacao, de: de, para: @item.nome_do_status, motivo: @motivo })
        end
        Core::Resultado.sucesso(@item)
      end

      private

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @item)
    end
  end
end
