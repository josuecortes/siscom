module Transporte
  # Um trecho do serviço de uma solicitação (ida ou busca), feito por um motorista com um veículo.
  # Aberto enquanto não tem `finalizado_em`.
  class Servico < ApplicationRecord
    self.table_name = "transporte_servicos"

    TRECHOS = { "ida" => "Ida", "busca" => "Busca" }.freeze

    belongs_to :solicitacao, class_name: "Transporte::Solicitacao", inverse_of: :servicos
    belongs_to :motorista, class_name: "User"
    belongs_to :veiculo, class_name: "Transporte::Veiculo"

    enum :trecho, TRECHOS.keys.index_by(&:itself), prefix: :de, validate: true

    validates :odometro_inicial, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :odometro_final, numericality: { only_integer: true, greater_than_or_equal_to: :odometro_inicial, message: "não pode ser menor que o inicial" }, allow_nil: true

    scope :abertos, -> { where(finalizado_em: nil) }
    scope :em_ordem, -> { order(:iniciado_em, :id) }

    # Os outros trechos da mesma viagem (saída em grupo).
    def companheiros = grupo.present? ? Transporte::Servico.where(grupo: grupo).where.not(id: id).includes(:solicitacao) : Transporte::Servico.none

    def aberto? = finalizado_em.nil?
    def nome_do_trecho = TRECHOS[trecho]
    def km_rodados = odometro_final ? odometro_final - odometro_inicial : nil
  end
end
