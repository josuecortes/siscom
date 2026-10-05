module Transporte
  module Veiculos
    # Cadastra ou atualiza um veículo, com auditoria.
    class Salvar
      PERMISSAO = "transporte.veiculos.gerenciar".freeze
      CAMPOS = %i[placa marca modelo ano cor capacidade combustivel consumo_km_por_litro odometro_atual].freeze

      def self.call(...) = new(...).call

      def initialize(veiculo:, atributos:, salvo_por:)
        @veiculo = veiculo
        @atributos = atributos.to_h.symbolize_keys.slice(*CAMPOS)
        @salvo_por = salvo_por
      end

      def call
        unless Core::Autorizacao.new(@salvo_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode cadastrar veículos.", objeto: @veiculo)
        end

        novo = @veiculo.new_record?
        return Core::Resultado.falha(@veiculo) unless @veiculo.update(@atributos)

        mudancas = @veiculo.saved_changes.except("id", "created_at", "updated_at").transform_values { |de, para| { de: de, para: para } }
        if mudancas.any?
          Core::Api.auditar(evento: "transporte.veiculo.#{novo ? 'cadastrado' : 'atualizado'}", alvo: @veiculo, ator: @salvo_por,
                            dados: (novo ? { placa: @veiculo.placa } : { mudancas: mudancas }))
        end
        Core::Resultado.sucesso(@veiculo)
      end
    end
  end
end
