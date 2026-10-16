module Equipamentos
  # Um envio de equipamentos de uma unidade para uma pessoa de outra (porta de movimentacao_equipamento.rb).
  # Tipos: movimentação (definitiva: recebido, o equipamento passa a ser da nova unidade), empréstimo e cautela
  # (o equipamento continua da unidade de origem e volta; quem recebe aceita um termo de responsabilidade).
  class Movimentacao < ApplicationRecord
    self.table_name = "equipamentos_movimentacoes"

    TIPOS = { "movimentacao" => "Movimentação", "emprestimo" => "Empréstimo", "cautela" => "Cautela" }.freeze
    STATUS = { "em_andamento" => "Em andamento", "concluida" => "Concluída", "cancelada" => "Cancelada" }.freeze
    DE_EMPRESTIMO = %w[emprestimo cautela].freeze

    belongs_to :responsavel, class_name: "User"
    belongs_to :criada_por, class_name: "User"
    has_many :itens, -> { order(:id) }, class_name: "Equipamentos::ItemMovimentacao", foreign_key: :movimentacao_id, inverse_of: :movimentacao, dependent: :destroy
    has_many :equipamentos, through: :itens, source: :item

    enum :tipo, TIPOS.keys.index_by(&:itself), prefix: :de, validate: true
    enum :status, STATUS.keys.index_by(&:itself), validate: true

    validates :origem_rh_unidade_id, :origem_nome, :destino_rh_unidade_id, :destino_nome, :responsavel_nome, :criada_por_nome, presence: true
    validates :previsao_devolucao, presence: true, if: :emprestimo?

    after_create :gerar_codigo

    scope :recentes, -> { order(created_at: :desc, id: :desc) }
    scope :definitivas, -> { where(tipo: "movimentacao") }
    scope :emprestimos, -> { where(tipo: DE_EMPRESTIMO) }
    scope :das_unidades, ->(ids) { where(origem_rh_unidade_id: ids).or(where(destino_rh_unidade_id: ids)) }

    def emprestimo? = DE_EMPRESTIMO.include?(tipo)
    def nome_do_tipo = TIPOS[tipo]
    def nome_do_status = STATUS[status]
    def aceita? = aceita_em.present?

    # Dias de atraso na devolução (0 quando está no prazo ou não é empréstimo em aberto).
    def dias_de_atraso(hoje = Date.current)
      return 0 unless emprestimo? && em_andamento? && aceita? && previsao_devolucao && previsao_devolucao < hoje

      (hoje - previsao_devolucao).to_i
    end

    def dias_emprestado(hoje = Date.current) = aceita? ? (hoje - aceita_em.to_date).to_i : 0

    private

    def gerar_codigo
      update_column(:codigo, format("%s-%06d", (emprestimo? ? "EM" : "MV"), id)) if codigo.blank?
    end
  end
end
