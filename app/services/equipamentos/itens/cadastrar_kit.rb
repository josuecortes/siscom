module Equipamentos
  module Itens
    # Cadastra um kit: várias peças de uma vez, com o mesmo código de kit, identificação, descrição, contrato,
    # processo e unidade (porta de Equipamento.criar_equipamentos_do_kit). Ou grava todas as peças, ou nenhuma.
    # Em falha, `objeto` é a lista das peças montadas (com os erros de cada uma) para o formulário voltar preenchido.
    class CadastrarKit
      COMUNS = %i[descricao contrato processo].freeze
      DA_PECA = %i[tipo_equipamento marca modelo numero_serial numero_patrimonio outra_identificacao garantia host ip mac ativo_de_rede].freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, pecas:, salvo_por:)
        @dados = atributos.to_h.symbolize_keys
        @pecas = lista(pecas).map { |peca| peca.to_h.symbolize_keys.slice(*DA_PECA) }.reject { |peca| peca.values.all?(&:blank?) }
        @salvo_por = salvo_por
      end

      def call
        unidade = Rh::Api.unidade(@dados[:rh_unidade_id])
        identificacao = @dados[:identificacao_kit].to_s.squish
        itens = montar(unidade, identificacao)
        return falha("Escolha a unidade do kit.", itens) unless unidade
        return falha("Você não pode cadastrar equipamentos nesta unidade.", itens) unless Acesso.pode?(@salvo_por, Acesso::GERENCIAR) && Acesso.age_na_unidade?(@salvo_por, unidade.id)
        return falha("Identificação do kit deve ser preenchida.", itens) if identificacao.blank?
        return falha("O kit deve ter pelo menos uma peça.", itens) if itens.empty?
        return falha(repetidos(itens), itens) if repetidos(itens)
        return falha("Revise as peças destacadas.", itens) unless itens.map(&:valid?).all?

        Equipamentos::Item.transaction do
          codigo = Equipamentos::Item.proximo_codigo_de_kit
          itens.each do |item|
            item.codigo_kit = codigo
            item.save!
            item.registrar_evento("cadastrado", @salvo_por, "Cadastrado em #{item.unidade_nome}, no kit #{identificacao} (#{codigo}).")
          end
          Core::Api.auditar(evento: "equipamentos.kit.cadastrado", alvo: itens.first, ator: @salvo_por,
                            dados: { codigo_kit: codigo, identificacao_kit: identificacao, pecas: itens.size, unidade: unidade.sigla_e_nome })
        end
        Core::Resultado.sucesso(itens)
      end

      private

      # As peças vêm do formulário como { "0" => {...}, "1" => {...} } ou como lista.
      def lista(valor) = valor.respond_to?(:values) ? valor.to_h.sort_by { |chave, _| chave.to_s.to_i }.map(&:last) : Array(valor)

      def montar(unidade, identificacao)
        @pecas.map do |peca|
          Equipamentos::Item.new(peca.merge(@dados.slice(*COMUNS)).merge(identificacao_kit: identificacao, rh_unidade_id: unidade&.id,
                                                                         unidade_nome: unidade&.sigla_e_nome, cadastrado_por: @salvo_por))
        end
      end

      # Duas peças do mesmo kit com o mesmo serial ou patrimônio (o banco só veria a segunda ao gravar).
      def repetidos(itens)
        %i[numero_serial numero_patrimonio].each do |campo|
          valores = itens.filter_map { |item| item[campo] }
          repetido = valores.detect { |valor| valores.count(valor) > 1 }
          return "#{Equipamentos::Item::CAMPOS[campo]} #{repetido} está em mais de uma peça do kit." if repetido
        end
        nil
      end

      def falha(mensagem, itens) = Core::Resultado.falha(mensagem, objeto: itens)
    end
  end
end
