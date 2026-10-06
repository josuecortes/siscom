module Equipamentos
  # Um equipamento dentro de um envio. Movimentação: pendente → recebido (ou cancelado).
  # Empréstimo/cautela: pendente → emprestado (termo aceito) → devolucao_pendente → devolvido (ou cancelado).
  class ItemMovimentacao < ApplicationRecord
    self.table_name = "equipamentos_itens_movimentacao"

    STATUS = { "pendente" => "Aguardando recebimento", "recebido" => "Recebido", "cancelado" => "Cancelado", "emprestado" => "Emprestado",
               "devolucao_pendente" => "Devolução aguardando recebimento", "devolvido" => "Devolvido" }.freeze
    ABERTOS = %w[pendente emprestado devolucao_pendente].freeze

    belongs_to :movimentacao, class_name: "Equipamentos::Movimentacao", inverse_of: :itens
    belongs_to :item, class_name: "Equipamentos::Item", inverse_of: :itens_de_movimentacao
    belongs_to :recebido_por, class_name: "User", optional: true
    belongs_to :cancelado_por, class_name: "User", optional: true
    belongs_to :devolver_para, class_name: "User", optional: true
    belongs_to :devolucao_recebida_por, class_name: "User", optional: true

    enum :status, STATUS.keys.index_by(&:itself), validate: true

    scope :abertos, -> { where(status: ABERTOS) }

    def nome_do_status = STATUS[status]
    def aberto? = ABERTOS.include?(status)
  end
end
