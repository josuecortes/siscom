module Rh
  # Dados que só as escolas têm (porta de school_detail.rb): NAE, código INEP, endereço.
  class DadosEscola < ApplicationRecord
    self.table_name = "rh_dados_escola"

    belongs_to :unidade, class_name: "Rh::Unidade", inverse_of: :dados_escola

    validates :unidade_id, uniqueness: true
    validate :unidade_e_escola

    private

    def unidade_e_escola
      errors.add(:unidade, "deve ser uma escola") if unidade && !unidade.escola?
    end
  end
end
