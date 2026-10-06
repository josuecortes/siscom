module Rh
  # Unidade organizacional (porta de organizational_unit.rb): gabinete, coordenadoria,
  # núcleo, escola... em árvore (uma unidade pode ter uma unidade pai).
  class Unidade < ApplicationRecord
    self.table_name = "rh_unidades"

    STATUS = %w[ativo inativo].freeze

    belongs_to :tipo_unidade, class_name: "Rh::TipoUnidade", inverse_of: :unidades
    belongs_to :tipo_local, class_name: "Rh::TipoLocal", optional: true, inverse_of: :unidades
    belongs_to :pai, class_name: "Rh::Unidade", optional: true, inverse_of: :filhas
    has_many :filhas, class_name: "Rh::Unidade", foreign_key: :pai_id, inverse_of: :pai, dependent: :restrict_with_error
    has_one :dados_escola, class_name: "Rh::DadosEscola", inverse_of: :unidade, dependent: :destroy
    has_many :lotacoes, class_name: "Rh::Lotacao", inverse_of: :unidade, dependent: :restrict_with_error

    accepts_nested_attributes_for :dados_escola, update_only: true

    enum :status, STATUS.index_by(&:itself), validate: true

    normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }
    normalizes :sigla, with: ->(sigla) { sigla.to_s.squish.upcase.presence }

    validates :nome, presence: true, length: { maximum: 200 }
    validates :sigla, uniqueness: { case_sensitive: false }, length: { maximum: 30 }, allow_nil: true
    # Escola pode ficar sem sigla (no siscom antigo todas usavam a sigla genérica "ESCOLA").
    validates :sigla, presence: true, unless: :escola?
    validate :pai_nao_cria_ciclo

    scope :ordenadas, -> { order(:nome) }
    scope :raizes, -> { where(pai_id: nil) }
    scope :buscar, lambda { |termo|
      where(Busca.em("rh_unidades.nome", "rh_unidades.sigla"), t: Busca.padrao(termo))
    }

    def escola? = tipo_unidade&.nome.to_s.casecmp?("ESCOLA")

    # "ASCOM - ASSESSORIA DE COMUNICAÇÃO" (ou só o nome, sem sigla)
    def sigla_e_nome = [ sigla, nome ].compact.join(" - ")

    # Da raiz até a própria unidade.
    def caminho
      atual = self
      lista = [ atual ]
      lista.unshift(atual) while (atual = atual.pai) && lista.exclude?(atual)
      lista
    end

    def ids_descendentes
      ids = []
      nivel = [ id ]
      while (nivel = self.class.where(pai_id: nivel).pluck(:id) - ids).any?
        ids.concat(nivel)
      end
      ids
    end

    private

    def pai_nao_cria_ciclo
      return if pai_id.blank?

      errors.add(:pai_id, "não pode ser a própria unidade") if pai_id == id
      errors.add(:pai_id, "não pode ser uma unidade abaixo desta") if persisted? && ids_descendentes.include?(pai_id)
    end
  end
end
