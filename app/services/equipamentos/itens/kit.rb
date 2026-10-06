module Equipamentos
  module Itens
    # Põe um equipamento num kit que já existe (pelo código) ou tira do kit em que está
    # (porta de verificar_kit / remover_de_kit do siscom antigo). A peça entra no kit da MESMA unidade.
    class Kit
      def self.entrar(...) = new(...).entrar
      def self.sair(...) = new(...).sair

      # Dados de um kit pelo código, para conferir antes de incluir: { identificacao:, unidade:, pecas: } ou nil.
      def self.resumo(codigo)
        pecas = Equipamentos::Item.where(codigo_kit: codigo.to_s.squish.upcase)
        primeira = pecas.order(:id).first
        primeira && { codigo: primeira.codigo_kit, identificacao: primeira.identificacao_kit, unidade: primeira.unidade_nome, pecas: pecas.count }
      end

      def initialize(item:, ator:, codigo: nil)
        @item = item
        @ator = ator
        @codigo = codigo.to_s.squish.upcase
      end

      def entrar
        erro = bloqueio
        return falha(erro) if erro

        modelo = Equipamentos::Item.where(codigo_kit: @codigo).order(:id).first
        return falha("Não há kit com o código #{@codigo}.") if @codigo.blank? || modelo.nil?
        return falha("O kit #{@codigo} é de outra unidade (#{modelo.unidade_nome}).") unless modelo.rh_unidade_id == @item.rh_unidade_id

        gravar(codigo_kit: modelo.codigo_kit, identificacao_kit: modelo.identificacao_kit, nota: "Entrou no kit #{modelo.identificacao_kit} (#{modelo.codigo_kit}).")
      end

      def sair
        erro = bloqueio
        return falha(erro) if erro
        return falha("Este equipamento não está em nenhum kit.") unless @item.no_kit?

        gravar(codigo_kit: nil, identificacao_kit: nil, nota: "Saiu do kit #{@item.identificacao_kit} (#{@item.codigo_kit}).")
      end

      private

      def bloqueio
        return "Você não pode alterar este equipamento." unless Acesso.pode_gerenciar?(@ator, @item)

        "Este equipamento está #{@item.nome_da_situacao.downcase} e não pode ser alterado agora." unless @item.disponivel?
      end

      def gravar(codigo_kit:, identificacao_kit:, nota:)
        antes = [ @item.codigo_kit, codigo_kit ]
        Equipamentos::Item.transaction do
          @item.update!(codigo_kit: codigo_kit, identificacao_kit: identificacao_kit)
          @item.registrar_evento("kit_alterado", @ator, nota, mudancas: { "codigo_kit" => antes })
          Core::Api.auditar(evento: "equipamentos.item.kit_alterado", alvo: @item, ator: @ator, dados: { identificacao: @item.identificacao, de: antes.first, para: antes.last })
        end
        Core::Resultado.sucesso(@item)
      end

      def falha(mensagem) = Core::Resultado.falha(mensagem, objeto: @item)
    end
  end
end
