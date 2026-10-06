module Core
  # Fonte de referência publicada (porta de reference_source.rb do seed): diz de
  # qual entidade vêm as opções de um campo de busca/seleção e quais campos mostrar.
  class FonteReferencia < ApplicationRecord
    self.table_name = "core_fontes_referencia"

    STATUS = %w[ativo inativo].freeze
    TIPOS_DE_CAMPO = { "selecao_unica" => "Seleção única", "selecao_multipla" => "Seleção múltipla" }.freeze
    ESTRUTURA = %w[modulo entidade campo_rotulo campo_valor campo_subtitulo campos_busca tipos_de_campo].freeze

    enum :status, STATUS.index_by(&:itself), validate: true

    normalizes :chave, with: ->(chave) { chave.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") }
    normalizes :nome, with: ->(nome) { nome.to_s.squish }
    normalizes :campo_subtitulo, with: ->(campo) { campo.presence }
    normalizes :campos_busca, :tipos_de_campo, with: ->(lista) { Array(lista).map { |item| item.to_s.strip }.compact_blank.uniq }

    validates :chave, presence: true, uniqueness: { case_sensitive: false }
    validates :nome, :modulo, :entidade, :campo_rotulo, :campo_valor, presence: true
    validate :entidade_publicavel
    validate :campos_da_entidade
    validate :tipos_validos
    validate :estrutura_protegida, on: :update

    scope :ordenadas, -> { order(:nome, :chave) }
    scope :buscar, lambda { |termo|
      where(Busca.em("nome", "chave", "modulo", "entidade"), t: Busca.padrao(termo))
    }

    def definicao = Core::FontesReferencia::Entidades.buscar(modulo, entidade)

    def nome_do_modulo = Core::Catalogo.modulo(modulo)&.nome || modulo

    private

    def entidade_publicavel
      errors.add(:entidade, "não é uma entidade publicável") if entidade.present? && definicao.nil?
    end

    def campos_da_entidade
      return unless definicao

      disponiveis = definicao.campos
      errors.add(:campo_rotulo, "não pertence à entidade selecionada") if campo_rotulo.present? && disponiveis.exclude?(campo_rotulo)
      errors.add(:campo_valor, "não pertence à entidade selecionada") if campo_valor.present? && disponiveis.exclude?(campo_valor)
      errors.add(:campo_subtitulo, "não pertence à entidade selecionada") if campo_subtitulo.present? && disponiveis.exclude?(campo_subtitulo)
      errors.add(:campos_busca, "deve ter ao menos um campo") if campos_busca.blank?
      errors.add(:campos_busca, "tem campos que não pertencem à entidade selecionada") if (campos_busca - disponiveis).any?
    end

    def tipos_validos
      errors.add(:tipos_de_campo, "deve ter ao menos um tipo") if tipos_de_campo.blank?
      errors.add(:tipos_de_campo, "tem tipos inválidos") if (tipos_de_campo - TIPOS_DE_CAMPO.keys).any?
    end

    def estrutura_protegida
      return unless gerenciada_pelo_sistema? && (changed & ESTRUTURA).any? && !@liberar_estrutura

      errors.add(:base, "Esta fonte é gerenciada pelo sistema e não pode ter a estrutura alterada.")
    end

    public

    # Só o próprio sistema (Publicar) ajusta a estrutura de uma fonte gerenciada.
    def salvar_pelo_sistema!
      @liberar_estrutura = true
      save!
    ensure
      @liberar_estrutura = false
    end
  end
end
