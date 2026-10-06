module Transporte
  # Veículo (porta de transport_vehicle.rb do seed). O odômetro atual só anda para a frente: é
  # atualizado pelos serviços e serve de piso para o odômetro inicial do próximo.
  class Veiculo < ApplicationRecord
    self.table_name = "transporte_veiculos"

    STATUS = %w[ativo inativo].freeze
    COMBUSTIVEIS = { "gasolina" => "Gasolina", "diesel" => "Diesel", "flex" => "Flex", "eletrico" => "Elétrico", "hibrido" => "Híbrido" }.freeze

    enum :status, STATUS.index_by(&:itself), validate: true
    enum :combustivel, COMBUSTIVEIS.keys.index_by(&:itself), prefix: :movido_a, validate: true

    normalizes :placa, with: ->(placa) { placa.to_s.gsub(/[^A-Za-z0-9]/, "").upcase }
    normalizes :marca, :modelo, :cor, with: ->(texto) { texto.to_s.squish.upcase }

    validates :marca, :modelo, :cor, presence: true, length: { maximum: 60 }
    validates :placa, presence: true, uniqueness: { case_sensitive: false },
                      format: { with: /\A[A-Z]{3}\d[A-Z0-9]\d{2}\z/, message: "deve ter o formato ABC1234 ou ABC1D23" }
    validates :ano, numericality: { only_integer: true, greater_than_or_equal_to: 1950, less_than_or_equal_to: ->(_) { Date.current.year + 1 } }
    validates :capacidade, numericality: { only_integer: true, greater_than: 0 }
    validates :consumo_km_por_litro, numericality: { greater_than: 0 }
    validates :odometro_atual, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

    scope :ordenados, -> { order(:placa) }
    scope :buscar, ->(termo) {
      where(Busca.em("placa", "marca", "modelo"), t: Busca.padrao(termo).delete("-"))
    }

    def descricao = "#{placa} · #{marca} #{modelo}"
    def nome_do_combustivel = COMBUSTIVEIS[combustivel]
  end
end
