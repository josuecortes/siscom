module Rh
  class TipoUnidade < ApplicationRecord
    include TabelaDeReferencia

    self.table_name = "rh_tipos_unidade"

    has_many :unidades, class_name: "Rh::Unidade", foreign_key: :tipo_unidade_id, inverse_of: :tipo_unidade, dependent: :restrict_with_error
  end
end
