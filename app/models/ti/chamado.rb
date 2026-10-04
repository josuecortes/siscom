module Ti
  # Chamado de TI (porta de helpdesk_ticket.rb). Nasce "aberto"; triagem e atendimento são
  # ações da operação. Guarda o retrato do solicitante e da unidade na abertura.
  class Chamado < ApplicationRecord
    self.table_name = "ti_chamados"

    STATUS = {
      "aberto" => "Aberto", "em_triagem" => "Em triagem", "aguardando_solicitante" => "Ajustar solicitação",
      "aguardando_tecnico" => "Aguardando técnico", "em_atendimento" => "Em trabalho", "impedido" => "Impedido",
      "concluido" => "Concluído", "finalizado" => "Finalizado", "cancelado" => "Cancelado"
    }.freeze
    # Estados em que o chamado ainda conta como "em aberto" para o solicitante.
    EM_ANDAMENTO = %w[aberto em_triagem aguardando_solicitante aguardando_tecnico em_atendimento impedido].freeze

    # Mais urgente primeiro (para ordenar as listas da operação).
    ORDEM_DE_PRIORIDADE = "CASE ti_chamados.prioridade WHEN 'critica' THEN 0 WHEN 'urgente' THEN 1 WHEN 'alta' THEN 2 ELSE 3 END".freeze

    belongs_to :problema, class_name: "Ti::Problema", inverse_of: :chamados
    belongs_to :solicitante, class_name: "User"
    belongs_to :aberto_por, class_name: "User", optional: true # quando a TI abre em nome do solicitante
    belongs_to :triador, class_name: "User", optional: true
    belongs_to :responsavel, class_name: "User", optional: true
    has_many :eventos, class_name: "Ti::EventoChamado", foreign_key: :chamado_id, inverse_of: :chamado, dependent: :destroy
    has_many :valores, class_name: "Ti::ValorCampo", foreign_key: :chamado_id, inverse_of: :chamado, dependent: :destroy

    enum :status, STATUS.keys.index_by(&:itself), validate: true
    enum :prioridade, Ti::Problema::PRIORIDADES.keys.index_by(&:itself), prefix: :prioridade, validate: true

    AVALIACOES = { 5 => "Muito bom", 4 => "Bom", 3 => "Normal", 2 => "Ruim", 1 => "Péssimo" }.freeze

    validates :solicitante_nome, :solicitante_email, :aberto_em, presence: true

    after_create :gerar_codigo

    scope :em_andamento, -> { where(status: EM_ANDAMENTO) }
    scope :recentes, -> { order(aberto_em: :desc, id: :desc) }
    scope :buscar, ->(termo) {
      padrao = "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%"
      joins(:problema).where("ti_chamados.codigo LIKE :t OR ti_problemas.nome LIKE :t", t: padrao)
    }

    scope :buscar_na_operacao, ->(termo) {
      padrao = "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%"
      joins(:problema).where("ti_chamados.codigo LIKE :t OR ti_problemas.nome LIKE :t OR ti_chamados.solicitante_nome LIKE :t OR ti_chamados.unidade_nome LIKE :t", t: padrao)
    }

    def nome_do_status = STATUS[status]
    def nome_da_prioridade = Ti::Problema::PRIORIDADES[prioridade]
    def em_andamento? = EM_ANDAMENTO.include?(status)
    def nome_da_avaliacao = AVALIACOES[avaliacao]

    # O solicitante ainda pode mexer nos dados (antes de alguém pegar, ou quando a TI pede ajuste).
    def editavel_pelo_solicitante? = aberto? || aguardando_solicitante?
    def cancelavel_pelo_solicitante? = aberto? || aguardando_solicitante?

    private

    def gerar_codigo
      update_column(:codigo, format("TI-%06d", id)) if codigo.blank?
    end
  end
end
