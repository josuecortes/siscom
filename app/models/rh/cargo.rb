module Rh
  class Cargo < ApplicationRecord
    include TabelaDeReferencia

    self.table_name = "rh_cargos"

    has_many :vinculos, class_name: "Rh::Vinculo", foreign_key: :cargo_id, inverse_of: :cargo, dependent: :restrict_with_error
  end
end
