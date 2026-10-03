module Core
  module Auditoria
    # Grava um registro de auditoria. O ator e o IP vêm do Core::Contexto quando
    # não são informados. Nunca coloque senhas ou segredos em `dados` (chaves com
    # senha/password/token/segredo são descartadas).
    #
    #   Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: user, dados: { email: user.email })
    class Registrar
      CHAVES_PROIBIDAS = /senha|password|token|segredo/i

      def self.call(...) = new(...).call

      # evento: "<modulo>.<objeto>.<acao>"; ator: User, nil (sistema) ou :contexto.
      def initialize(evento:, alvo: nil, dados: {}, ator: :contexto, descricao: nil)
        @modulo, @evento = evento.to_s.split(".", 2)
        @alvo = alvo
        @dados = limpar(dados || {})
        @ator = ator == :contexto ? Core::Contexto.ator : ator
        @descricao = descricao
      end

      def call
        Core::RegistroAuditoria.create!(
          modulo: @modulo, evento: @evento,
          ator: @ator, ator_nome: @ator&.nome,
          alvo_tipo: @alvo&.class&.name, alvo_id: @alvo&.id, alvo_descricao: @descricao || descrever(@alvo),
          dados: @dados, ip: Core::Contexto.ip, request_id: Core::Contexto.request_id
        )
      end

      private

      def descrever(alvo)
        return if alvo.nil?
        return alvo.nome if alvo.respond_to?(:nome) && alvo.nome.present?

        "#{alvo.class.model_name.human} ##{alvo.id}"
      end

      def limpar(dados)
        dados.to_h.deep_stringify_keys.reject { |chave, _| chave.match?(CHAVES_PROIBIDAS) }.transform_values do |valor|
          valor.is_a?(Hash) ? limpar(valor) : valor
        end
      end
    end
  end
end
