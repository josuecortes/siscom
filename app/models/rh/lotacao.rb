module Rh
  # Lotação: a pessoa atua numa unidade com uma função (porta de assignment.rb).
  # Encerrar não apaga: fecha a data de fim e fica como histórico.
  class Lotacao < ApplicationRecord
    self.table_name = "rh_lotacoes"

    STATUS = %w[ativo inativo].freeze

    belongs_to :pessoa, class_name: "Rh::Pessoa", inverse_of: :lotacoes
    belongs_to :unidade, class_name: "Rh::Unidade", inverse_of: :lotacoes
    belongs_to :funcao, class_name: "Rh::Funcao", inverse_of: :lotacoes

    enum :status, STATUS.index_by(&:itself), validate: true
    datas_br :data_inicio, :data_fim

    validates :data_inicio, :lotado_em, presence: true
    validate :uma_ativa_por_pessoa_unidade_e_funcao
    validate :fim_depois_do_inicio

    scope :recentes, -> { order(data_inicio: :desc, id: :desc) }

    private

    def uma_ativa_por_pessoa_unidade_e_funcao
      return unless ativo? && pessoa_id && unidade_id && funcao_id

      repetida = self.class.ativo.where(pessoa_id:, unidade_id:, funcao_id:).where.not(id:)
      errors.add(:funcao_id, "já existe uma lotação ativa para essa pessoa nesta unidade com esta função") if repetida.exists?
    end

    def fim_depois_do_inicio
      errors.add(:data_fim, "não pode ser anterior à data de início") if data_fim && data_inicio && data_fim < data_inicio
    end
  end
end
