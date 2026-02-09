class Mensagem < ApplicationRecord
  belongs_to :user
  belongs_to :requisicao_ti

  has_one_attached :imagem

  # status: lida, não lida

  validate :imagem_tamanho_maximo

  def marcar_como_lida
    self.status = "lida"
    self.save
  end

  def imagem_tamanho_maximo
    return unless imagem.attached?

    if imagem.blob.byte_size > 2.megabytes
      errors.add(:imagem, "O arquivo deve ser menor que 2MB.")
    end
  end
end
