module Rh
  # Comportamento comum das tabelas de referência do RH (tipos de unidade, tipos de
  # local, cargos, funções e tipos de vínculo): nome único, ativa/inativa.
  module TabelaDeReferencia
    extend ActiveSupport::Concern

    STATUS = %w[ativo inativo].freeze

    included do
      enum :status, STATUS.index_by(&:itself), validate: true

      normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }

      validates :nome, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 120 }

      scope :ordenados, -> { order(:nome) }
      scope :buscar, ->(termo) { where("nome LIKE ?", "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%") }
    end
  end
end
