class ServicoTransporte < ApplicationRecord
  belongs_to :requisicao_transporte
  belongs_to :veiculo
  belongs_to :motorista
end
