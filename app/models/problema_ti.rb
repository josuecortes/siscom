class ProblemaTi < ApplicationRecord
  belongs_to :tipo_problema_ti
  has_many :requisicao_tis
end
