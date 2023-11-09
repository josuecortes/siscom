class ServicoTransporte < ApplicationRecord
  belongs_to :requisicao_transporte
  belongs_to :veiculo
  belongs_to :motorista

  validates_presence_of :km_inicial
  validate :checar_km_final

  def checar_km_final
    if self.status == "finalizado"
      validates_presence_of :km_final
      if self.self.km_final and self.km_inicial >= self.km_final
        self.errors.add(:km_final, "Kilometragem final não pode ser menor que a kilometragem inicial")
      end
    end
  end
end
