module Transporte
  # Motorista (porta de transport_driver.rb do seed). É sempre ligado a uma conta de usuário, que
  # recebe a permissão de motorista e é quem inicia e finaliza os serviços.
  class Motorista < ApplicationRecord
    self.table_name = "transporte_motoristas"

    STATUS = %w[ativo inativo].freeze
    CATEGORIAS = %w[A B C D E AB AC AD AE].freeze

    belongs_to :user

    enum :status, STATUS.index_by(&:itself), validate: true
    datas_br :data_nascimento, :cnh_validade

    normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }
    normalizes :cpf, with: ->(cpf) { Cpf.digitos(cpf) }
    normalizes :cnh_numero, :cnh_categoria, with: ->(valor) { valor.to_s.strip.upcase }

    validates :nome, :data_nascimento, :cnh_validade, presence: true
    validates :cpf, presence: true, uniqueness: true
    validates :cnh_numero, presence: true, uniqueness: { case_sensitive: false }
    validates :cnh_categoria, inclusion: { in: CATEGORIAS, message: "deve ser uma categoria válida" }
    validates :user_id, uniqueness: { message: "já é motorista" }
    validate :cpf_valido

    scope :ordenados, -> { order(:nome, :id) }
    scope :buscar, ->(termo) {
      texto = termo.to_s.squish
      where(Busca.em("transporte_motoristas.nome", "transporte_motoristas.cnh_numero"), t: Busca.padrao(texto))
        .or(where("transporte_motoristas.cpf LIKE ?", "%#{sanitize_sql_like(Cpf.digitos(texto).presence || texto)}%"))
    }

    def cnh_vencida? = cnh_validade.present? && cnh_validade < Date.current

    private

    def cpf_valido
      errors.add(:cpf, :invalid) if cpf.present? && !Cpf.valido?(cpf)
    end
  end
end
