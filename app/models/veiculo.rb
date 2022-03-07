class Veiculo < ApplicationRecord
    validates_presence_of :placa, :marca, :modelo, :combustivel, :capacidade, :carga, :status
    validates_uniqueness_of :placa

    has_many :servico_transportes, dependent: :destroy
end