class Veiculo < ApplicationRecord
    validates_presence_of :placa, :marca, :modelo, :combustivel, :capacidade, :carga, :status
    validates_uniqueness_of :placa
end