class Departamento < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :requisicao_tis, dependent: :restrict_with_error

  validates_presence_of :nome, :sigla
end
