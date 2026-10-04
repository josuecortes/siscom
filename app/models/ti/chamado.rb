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

    belongs_to :problema, class_name: "Ti::Problema", inverse_of: :chamados
    belongs_to :solicitante, class_name: "User"
    belongs_to :aberto_por, class_name: "User", optional: true # quando a TI abre em nome do solicitante
    belongs_to :triador, class_name: "User", optional: true
    belongs_to :responsavel, class_name: "User", optional: true
    has_many :eventos, class_name: "Ti::EventoChamado", foreign_key: :chamado_id, inverse_of: :chamado, dependent: :destroy
    has_many :valores, class_name: "Ti::ValorCampo", foreign_key: :chamado_id, inverse_of: :chamado, dependent: :destroy

    enum :status, STATUS.keys.index_by(&:itself), validate: true
    enum :prioridade, Ti::Problema::PRIORIDADES.keys.index_by(&:itself), prefix: :prioridade, validate: true

    validates :solicitante_nome, :solicitante_email, :aberto_em, presence: true

    after_create :gerar_codigo

    scope :em_andamento, -> { where(status: EM_ANDAMENTO) }
    scope :recentes, -> { order(aberto_em: :desc, id: :desc) }
    scope :buscar, ->(termo) {
      padrao = "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%"
      joins(:problema).where("ti_chamados.codigo LIKE :t OR ti_problemas.nome LIKE :t", t: padrao)
    }

    def nome_do_status = STATUS[status]
    def nome_da_prioridade = Ti::Problema::PRIORIDADES[prioridade]
    def em_andamento? = EM_ANDAMENTO.include?(status)

    private

    def gerar_codigo
      update_column(:codigo, format("TI-%06d", id)) if codigo.blank?
    end
  end
end
