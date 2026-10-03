module Rh
  class TipoVinculo < ApplicationRecord
    include TabelaDeReferencia

    self.table_name = "rh_tipos_vinculo"

    has_many :vinculos, class_name: "Rh::Vinculo", foreign_key: :tipo_vinculo_id, inverse_of: :tipo_vinculo, dependent: :restrict_with_error
  end
end
