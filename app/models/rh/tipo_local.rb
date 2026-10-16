module Rh
  class TipoLocal < ApplicationRecord
    include TabelaDeReferencia

    self.table_name = "rh_tipos_local"

    has_many :unidades, class_name: "Rh::Unidade", foreign_key: :tipo_local_id, inverse_of: :tipo_local, dependent: :restrict_with_error
  end
end
