module Core
  # Inscrição de um aparelho/navegador para receber notificações push.
  class InscricaoPush < ApplicationRecord
    self.table_name = "core_inscricoes_push"

    belongs_to :user, class_name: "::User"

    validates :endpoint, presence: true, uniqueness: true
    validate :endpoint_de_servico_de_push
    validates :p256dh, :auth, presence: true

    private

    # O servidor envia requisições para este endereço: só https e só os serviços
    # de push dos navegadores (config.x.push.servicos), nunca um endereço qualquer.
    def endpoint_de_servico_de_push
      return if endpoint.blank?

      uri = URI.parse(endpoint)
      host = uri.host.to_s.downcase
      permitido = uri.is_a?(URI::HTTPS) &&
                  Rails.configuration.x.push.servicos.any? { |servico| host == servico || host.end_with?(".#{servico}") }
      errors.add(:endpoint, "não é de um serviço de push conhecido") unless permitido
    rescue URI::InvalidURIError
      errors.add(:endpoint, :invalid)
    end
  end
end
