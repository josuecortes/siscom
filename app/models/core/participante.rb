module Core
  # Quem participa de uma conversa e o que pode fazer nela.
  class Participante < ApplicationRecord
    self.table_name = "core_participantes"

    belongs_to :conversa, class_name: "Core::Conversa", inverse_of: :participantes
    belongs_to :user, class_name: "::User"

    scope :leitores, -> { where(pode_ler: true) }

    def nao_lidas
      mensagens = conversa.mensagens.where.not(autor_id: user_id)
      lida_ate_id ? mensagens.where("core_mensagens.id > ?", lida_ate_id).count : mensagens.count
    end

    def marcar_lida!
      ultima = conversa.mensagens.maximum(:id)
      update_column(:lida_ate_id, ultima) if ultima && ultima != lida_ate_id
    end
  end
end
