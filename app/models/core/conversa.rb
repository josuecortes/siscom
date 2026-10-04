module Core
  # Conversa ligada a um registro de um módulo (porta de chat_thread.rb do seed). Não é um chat
  # solto: quem participa e quando fica só para leitura é decidido pelo módulo dono, por
  # Core::Api.sincronizar_conversa.
  class Conversa < ApplicationRecord
    self.table_name = "core_conversas"

    STATUS = %w[ativa somente_leitura].freeze

    has_many :participantes, class_name: "Core::Participante", foreign_key: :conversa_id, inverse_of: :conversa, dependent: :destroy
    has_many :mensagens, class_name: "Core::Mensagem", foreign_key: :conversa_id, inverse_of: :conversa, dependent: :destroy

    enum :status, STATUS.index_by(&:itself), validate: true

    validates :modulo, :alvo_tipo, :alvo_id, :titulo, presence: true

    def self.de(alvo) = find_by(alvo_tipo: alvo.class.name, alvo_id: alvo.id)

    def participante(user) = participantes.find_by(user: user)
    def nome_do_modulo = Core::Catalogo.modulo(modulo)&.nome || modulo
  end
end
