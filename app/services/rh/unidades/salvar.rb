module Rh
  module Unidades
    # Cria ou atualiza uma unidade (e os dados de escola, quando for escola), com auditoria.
    class Salvar
      PERMISSAO = "rh.unidades.gerenciar".freeze
      CAMPOS = %i[nome sigla tipo_unidade_id tipo_local_id pai_id].freeze
      CAMPOS_DA_ESCOLA = %i[nae codigo_inep cep logradouro numero complemento bairro cidade uf].freeze

      def self.call(...) = new(...).call

      def initialize(unidade:, atributos:, salvo_por:)
        @unidade = unidade
        dados = atributos.to_h.deep_symbolize_keys
        @atributos = dados.slice(*CAMPOS)
        @escola = (dados[:dados_escola] || {}).slice(*CAMPOS_DA_ESCOLA)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode cadastrar ou editar unidades.", objeto: @unidade)
        end

        nova = @unidade.new_record?
        @unidade.assign_attributes(@atributos)
        salvou = Rh::Unidade.transaction do
          next false unless @unidade.save

          salvar_dados_da_escola
          true
        end
        return Core::Resultado.falha(@unidade) unless salvou

        registrar(nova)
        Core::Resultado.sucesso(@unidade)
      end

      private

      def salvar_dados_da_escola
        if @unidade.escola?
          dados = @unidade.dados_escola || @unidade.build_dados_escola
          dados.update!(@escola) if @escola.any?
        else
          @unidade.dados_escola&.destroy
        end
      end

      def registrar(nova)
        mudancas = @unidade.saved_changes.except("created_at", "updated_at", "id").transform_values { |de, para| { de: de, para: para } }
        return if mudancas.empty? && !nova

        Core::Api.auditar(evento: "rh.unidade.#{nova ? 'criada' : 'atualizada'}", alvo: @unidade, ator: @salvo_por,
                          dados: (nova ? { sigla: @unidade.sigla }.compact : { mudancas: mudancas }))
      end
    end
  end
end
