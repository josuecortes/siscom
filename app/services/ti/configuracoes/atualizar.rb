module Ti
  module Configuracoes
    # Atualiza as configurações da TI (hoje, a senha do painel de acompanhamento), com auditoria.
    class Atualizar
      PERMISSAO = "ti.configuracoes.gerenciar".freeze

      def self.call(...) = new(...).call

      def initialize(atributos:, atualizado_por:)
        @atributos = atributos.to_h.symbolize_keys.slice(:senha_do_painel)
        @atualizado_por = atualizado_por
      end

      def call
        configuracao = Ti::Configuracao.atual
        unless Core::Autorizacao.new(@atualizado_por).pode?(PERMISSAO)
          return Core::Resultado.falha("Você não pode alterar as configurações da TI.", objeto: configuracao)
        end
        return Core::Resultado.falha(configuracao) unless configuracao.update(@atributos)

        if configuracao.saved_change_to_senha_do_painel_digest?
          Core::Api.auditar(evento: "ti.configuracao.atualizada", alvo: configuracao, ator: @atualizado_por,
                            dados: { mudancas: { painel_de_acompanhamento: "acesso alterado" } })
        end
        Core::Resultado.sucesso(configuracao)
      end
    end
  end
end
