module Ti
  # Comportamento comum dos itens simples do catálogo da TI (categorias, perfis de
  # abertura e grupos técnicos): nome único, descrição, ativo/inativo.
  module ItemDeCatalogo
    extend ActiveSupport::Concern

    STATUS = %w[ativo inativo].freeze

    included do
      enum :status, STATUS.index_by(&:itself), validate: true

      normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }
      normalizes :descricao, with: ->(descricao) { descricao.to_s.squish.presence }

      validates :nome, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 120 }
      validates :descricao, length: { maximum: 300 }

      scope :ordenados, -> { order(:nome) }
      scope :buscar, ->(termo) { where("nome LIKE ?", "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%") }
    end
  end
end
