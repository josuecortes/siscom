class Destino < ApplicationRecord
  belongs_to :requisicao_transporte
  belongs_to :user
end
