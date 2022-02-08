class Funcao < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  # scope :search, -> (term) do
  #   where('LOWER(nome) LIKE :term or LOWER(email) LIKE :term', term: "%#{term.downcase}") if term.present?
  # end

  scope :search, -> (term) { where('LOWER(nome) LIKE ?', "%#{term.downcase}%") if term.present? }

  validates_presence_of :nome
end
