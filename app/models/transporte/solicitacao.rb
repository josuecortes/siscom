module Transporte
  # Solicitação de transporte (porta de transport_request.rb do seed): normal ou viagem, com
  # passageiros e destinos. Nasce "solicitada"; aprovação, serviço e busca são da operação.
  class Solicitacao < ApplicationRecord
    self.table_name = "transporte_solicitacoes"

    TIPOS = { "normal" => "Normal", "viagem" => "Viagem" }.freeze
    MODOS = { "esperar_no_local" => "Esperar no local", "buscar_depois" => "Buscar depois", "so_deixar" => "Só deixar" }.freeze
    # "reagendada": a operação mudou o horário de uma solicitação aprovada e o solicitante ainda não respondeu.
    STATUS = { "solicitada" => "Solicitada", "aprovada" => "Aprovada", "reagendada" => "Reagendada", "em_servico" => "Em serviço",
               "busca" => "Aguardando busca", "concluida" => "Concluída", "cancelada" => "Cancelada" }.freeze
    EM_ANDAMENTO = %w[solicitada aprovada reagendada em_servico busca].freeze
    ANTES_DO_SERVICO = %w[solicitada aprovada reagendada].freeze

    belongs_to :solicitante, class_name: "User"
    belongs_to :aberto_por, class_name: "User", optional: true
    belongs_to :aprovada_por, class_name: "User", optional: true
    belongs_to :cancelada_por, class_name: "User", optional: true
    belongs_to :reagendada_por, class_name: "User", optional: true
    has_many :passageiros, -> { order(:posicao, :id) }, class_name: "Transporte::Passageiro", foreign_key: :solicitacao_id, inverse_of: :solicitacao, dependent: :destroy
    has_many :destinos, -> { order(:posicao, :id) }, class_name: "Transporte::Destino", foreign_key: :solicitacao_id, inverse_of: :solicitacao, dependent: :destroy
    has_many :servicos, class_name: "Transporte::Servico", foreign_key: :solicitacao_id, inverse_of: :solicitacao, dependent: :destroy
    has_many :observacoes, class_name: "Transporte::Observacao", foreign_key: :solicitacao_id, inverse_of: :solicitacao, dependent: :destroy
    has_many :eventos, class_name: "Transporte::Evento", foreign_key: :solicitacao_id, inverse_of: :solicitacao, dependent: :destroy
    has_one_attached :documento_da_viagem

    enum :tipo, TIPOS.keys.index_by(&:itself), validate: true
    enum :modo, MODOS.keys.index_by(&:itself), validate: true
    enum :status, STATUS.keys.index_by(&:itself), validate: true

    normalizes :resumo, with: ->(resumo) { resumo.to_s.strip }

    validates :resumo, presence: true, length: { maximum: 1000 }
    validates :saida_em, :solicitante_nome, :solicitante_email, presence: true
    validates :retorno_em, presence: true, if: :viagem?
    validates :espera_horas, presence: true, if: :esperar_no_local?
    validates :busca_horas, presence: true, if: :buscar_depois?
    validate :retorno_depois_da_saida

    after_create :gerar_codigo

    scope :recentes, -> { order(created_at: :desc, id: :desc) }
    scope :em_andamento, -> { where(status: EM_ANDAMENTO) }
    scope :buscar, ->(termo) {
      padrao = "%#{sanitize_sql_like(termo.to_s.squish.upcase)}%"
      where("transporte_solicitacoes.codigo LIKE :t OR UPPER(transporte_solicitacoes.resumo) LIKE :t OR transporte_solicitacoes.solicitante_nome LIKE :t", t: padrao)
    }

    def nome_do_tipo = TIPOS[tipo]
    def nome_do_modo = MODOS[modo]
    def nome_do_status = STATUS[status]
    def em_andamento? = EM_ANDAMENTO.include?(status)
    def antes_do_servico? = ANTES_DO_SERVICO.include?(status)

    # Só dá para reagendar uma vez (a hora da busca não conta: é outro ajuste).
    def ja_reagendada? = reagendada_em.present?

    # Linha do histórico (dentro da transação de quem muda a solicitação).
    def registrar_evento(tipo, ator, nota = nil)
      eventos.create!(tipo: tipo, ator: ator, ator_nome: ator&.nome, nota: nota.to_s.squish.presence, ocorrido_em: Time.current)
    end

    # O trecho em andamento (ida ou busca), se houver.
    def servico_aberto = servicos.abertos.first

    # Pode sair: aprovada (ida) ou aguardando busca sem ninguém a caminho.
    def pode_iniciar_servico? = (aprovada? || busca?) && servico_aberto.nil?

    private

    def retorno_depois_da_saida
      errors.add(:retorno_em, "deve ser depois da saída") if retorno_em && saida_em && retorno_em <= saida_em
    end

    def gerar_codigo
      update_column(:codigo, format("TR-%06d", id)) if codigo.blank?
    end
  end
end
