module Transporte
  # Passageiro de uma solicitação de transporte.
  class Passageiro < ApplicationRecord
    self.table_name = "transporte_passageiros"

    belongs_to :solicitacao, class_name: "Transporte::Solicitacao", inverse_of: :passageiros

    normalizes :cpf, with: ->(cpf) { Cpf.digitos(cpf) }
    normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }

    validates :nome, presence: true, length: { maximum: 120 }
    validates :cpf, presence: true
    validate { errors.add(:cpf, :invalid) if cpf.present? && !Cpf.valido?(cpf) }
  end
end
