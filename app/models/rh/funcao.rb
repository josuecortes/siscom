module Rh
  class Funcao < ApplicationRecord
    include TabelaDeReferencia

    self.table_name = "rh_funcoes"

    has_many :lotacoes, class_name: "Rh::Lotacao", foreign_key: :funcao_id, inverse_of: :funcao, dependent: :restrict_with_error
  end
end
