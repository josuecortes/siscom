module Rh
  # Vínculo funcional da pessoa com a instituição (porta de employment_record.rb).
  class Vinculo < ApplicationRecord
    self.table_name = "rh_vinculos"

    belongs_to :pessoa, class_name: "Rh::Pessoa", inverse_of: :vinculo
    belongs_to :tipo_vinculo, class_name: "Rh::TipoVinculo", inverse_of: :vinculos
    belongs_to :cargo, class_name: "Rh::Cargo", inverse_of: :vinculos

    datas_br :data_inicio

    validates :data_inicio, presence: true
  end
end
