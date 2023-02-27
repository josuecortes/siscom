class Mensagem < ApplicationRecord
  belongs_to :user
  belongs_to :requisicao_ti

  has_one_attached :imagem

  # status: lida, não lida

  def marcar_como_lida
    self.status = "lida"
    self.save
  end
end
