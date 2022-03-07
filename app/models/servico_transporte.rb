class ServicoTransporte < ApplicationRecord
  belongs_to :requisicao
  belongs_to :veiculo
  belongs_to :motorista
end
