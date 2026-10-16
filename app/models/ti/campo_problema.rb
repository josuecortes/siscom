module Ti
  # Campo do formulário de uma solicitação (porta de helpdesk_problem_field.rb). O conjunto de
  # campos ativos, na ordem, é o formulário que o usuário preenche ao abrir o chamado.
  class CampoProblema < ApplicationRecord
    self.table_name = "ti_campos_problema"

    STATUS = %w[ativo inativo].freeze
    TIPOS = {
      "texto" => "Texto curto", "texto_longo" => "Texto longo", "selecao" => "Seleção (lista)", "selecao_unica" => "Seleção única (botões)",
      "selecao_multipla" => "Múltipla seleção", "sim_nao" => "Sim/Não", "data" => "Data", "numero" => "Número",
      "arquivo" => "Arquivo único", "arquivos" => "Múltiplos arquivos", "busca" => "Busca (uma opção)", "busca_multipla" => "Busca (várias opções)"
    }.freeze
    COM_OPCOES = %w[selecao selecao_unica selecao_multipla].freeze
    COM_FONTE = %w[busca busca_multipla].freeze
    COM_MASCARA = %w[texto numero].freeze
    MASCARAS = { "data" => "Data (dd/mm/aaaa)", "hora" => "Hora (hh:mm)", "data_hora" => "Data e hora", "cpf" => "CPF", "celular" => "Celular",
                 "telefone" => "Telefone fixo", "cnpj" => "CNPJ", "cep" => "CEP" }.freeze

    belongs_to :problema, class_name: "Ti::Problema", inverse_of: :campos

    enum :status, STATUS.index_by(&:itself), validate: true

    normalizes :rotulo, :exemplo, :ajuda, with: ->(texto) { texto.to_s.squish.presence }
    normalizes :mascara, with: ->(mascara) { mascara.presence }

    before_validation :gerar_chave, :definir_posicao, :limpar_config

    validates :rotulo, presence: true, length: { maximum: 120 }
    validates :tipo, inclusion: { in: TIPOS.keys }
    validates :mascara, inclusion: { in: MASCARAS.keys }, allow_nil: true
    validates :exemplo, length: { maximum: 120 }
    validates :ajuda, length: { maximum: 300 }
    validates :posicao, numericality: { only_integer: true, greater_than: 0 }
    validate :config_do_tipo

    scope :ordenados, -> { order(:posicao, :id) }

    def opcoes = Array(config["opcoes"])
    def opcoes=(valor)
      lista = valor.is_a?(String) ? valor.lines : Array(valor)
      self.config = config.merge("opcoes" => lista.map { |item| item.to_s.squish }.compact_blank.uniq)
    end

    def fonte = config["fonte"]
    def fonte=(chave)
      self.config = config.merge("fonte" => chave.to_s.strip.presence)
    end

    def com_opcoes? = COM_OPCOES.include?(tipo)
    def com_fonte? = COM_FONTE.include?(tipo)
    def nome_do_tipo = TIPOS[tipo]

    private

    # A chave identifica o campo nas respostas dos chamados: é gerada do nome e nunca muda.
    def gerar_chave
      return if chave.present? || rotulo.blank? || problema.nil?

      base = I18n.transliterate(rotulo).downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "").presence || "campo"
      usadas = problema.campos.where.not(id: id).pluck(:chave)
      self.chave = ([ base ] + (2..).lazy.map { |n| "#{base}_#{n}" }.first(usadas.size + 1)).find { |candidata| usadas.exclude?(candidata) }
    end

    def definir_posicao
      self.posicao = problema.campos.maximum(:posicao).to_i + 1 if problema && posicao.to_i <= 0
    end

    def limpar_config
      self.config = { "opcoes" => (opcoes if com_opcoes?), "fonte" => (fonte if com_fonte?) }.compact
      self.mascara = nil unless COM_MASCARA.include?(tipo)
    end

    def config_do_tipo
      errors.add(:opcoes, "deve ter ao menos uma opção") if com_opcoes? && opcoes.empty?
      return unless com_fonte?

      if fonte.blank?
        errors.add(:fonte, "deve ser escolhida")
      elsif Core::Api.fontes_de_referencia.none? { |item| item.chave == fonte }
        errors.add(:fonte, "não é uma fonte publicada")
      end
    end
  end
end
