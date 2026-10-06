module Equipamentos
  # Linha do histórico de um equipamento: quem fez o quê e quando. Nas alterações, `mudancas` guarda o antes e o
  # depois de cada campo ({ "marca" => ["DELL", "LENOVO"] }).
  class Evento < ApplicationRecord
    self.table_name = "equipamentos_eventos"

    TIPOS = { "cadastrado" => "Cadastro", "editado" => "Alteração", "situacao_alterada" => "Mudança de situação", "kit_alterado" => "Kit",
              "movimentacao_criada" => "Envio para outra unidade", "movimentacao_recebida" => "Recebido na nova unidade", "movimentacao_cancelada" => "Envio cancelado",
              "emprestimo_criado" => "Empréstimo ou cautela enviado", "emprestimo_aceito" => "Termo aceito", "emprestimo_cancelado" => "Empréstimo cancelado",
              "devolucao_pedida" => "Devolução iniciada", "devolucao_recebida" => "Devolvido", "legado" => "Registro do siscom antigo" }.freeze

    belongs_to :item, class_name: "Equipamentos::Item", inverse_of: :eventos
    belongs_to :ator, class_name: "User", optional: true

    validates :tipo, inclusion: { in: TIPOS.keys }
    validates :ocorrido_em, presence: true

    scope :em_ordem, -> { order(:ocorrido_em, :id) }
    scope :recentes, -> { order(ocorrido_em: :desc, id: :desc) }

    def titulo = TIPOS[tipo]
  end
end
