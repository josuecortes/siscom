class Etapa < ApplicationRecord
  belongs_to :acao

  has_many :etapa_users
  has_many :users, through: :etapa_users

  accepts_nested_attributes_for :etapa_users, reject_if: :all_blank, allow_destroy: true

  enum status: { "Não Iniciada": 1, "Em andamento": 2, "Finalizada": 3, "Paralizada": 4, "Cancelada": 5 }

  def nome_etapa_nome_acao
    acao = self.acao
    if acao
      "#{self.nome} | #{acao.nome}"
    else
      self.nome
    end
  end
end
