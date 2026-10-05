module Transporte
  module Configuracoes
    # Atualiza as configurações do Transporte, com auditoria do que mudou.
    class Atualizar
      PERMISSAO = "transporte.configuracoes.gerenciar".freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, atualizado_por:)
        @atributos = atributos.to_h.symbolize_keys.slice(*Transporte::Configuracao::CAMPOS)
        @atualizado_por = atualizado_por
      end

      def call
        configuracao = Transporte::Configuracao.atual
        unless Core::Autorizacao.new(@atualizado_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar as configurações do Transporte.", objeto: configuracao)
        end
        return Core::Resultado.falha(configuracao) unless configuracao.update(@atributos)

        mudancas = configuracao.saved_changes.except("updated_at").transform_values { |de, para| { de: de, para: para } }
        if mudancas.any?
          Core::Api.auditar(evento: "transporte.configuracao.atualizada", alvo: configuracao, ator: @atualizado_por, dados: { mudancas: mudancas })
        end
        Core::Resultado.sucesso(configuracao)
      end
    end
  end
end
