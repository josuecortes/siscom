module Ti
  # Resposta dada a um campo do formulário na abertura do chamado.
  class ValorCampo < ApplicationRecord
    self.table_name = "ti_valores_campo"


    belongs_to :chamado, class_name: "Ti::Chamado", inverse_of: :valores
    belongs_to :campo_problema, class_name: "Ti::CampoProblema"
    has_many_attached :arquivos

    scope :em_ordem, -> { joins(:campo_problema).order("ti_campos_problema.posicao", "ti_campos_problema.id") }
  end
end
