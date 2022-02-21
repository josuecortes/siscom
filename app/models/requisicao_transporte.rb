class RequisicaoTransporte < ApplicationRecord
  belongs_to :user
  belongs_to :departamento
end
