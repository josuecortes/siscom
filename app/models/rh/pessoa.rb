module Rh
  # Cadastro da pessoa (porta de person.rb). Cada pessoa pode estar ligada a uma
  # conta de usuário (`users`), e cada conta a no máximo uma pessoa.
  class Pessoa < ApplicationRecord
    self.table_name = "rh_pessoas"

    SEXOS = { "masculino" => "Masculino", "feminino" => "Feminino", "outro" => "Outro", "nao_informado" => "Não informado" }.freeze

    belongs_to :user, class_name: "::User", optional: true
    has_one :vinculo, class_name: "Rh::Vinculo", inverse_of: :pessoa, dependent: :destroy
    has_many :lotacoes, class_name: "Rh::Lotacao", inverse_of: :pessoa, dependent: :restrict_with_error

    accepts_nested_attributes_for :vinculo, update_only: true, reject_if: :all_blank

    enum :sexo, SEXOS.keys.index_by(&:itself), validate: true
    datas_br :data_nascimento

    normalizes :nome, with: ->(nome) { nome.to_s.squish.upcase }
    normalizes :email, with: ->(email) { email.to_s.strip.downcase }
    normalizes :cpf, :celular, with: ->(valor) { valor.to_s.gsub(/\D/, "").presence }

    validates :nome, presence: true, length: { maximum: 200 }
    validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :cpf, uniqueness: true, allow_nil: true
    validates :user_id, uniqueness: true, allow_nil: true
    validate :nome_e_sobrenome
    validate :cpf_valido
    validate :celular_valido

    scope :ordenadas, -> { order(:nome) }
    scope :buscar, lambda { |termo|
      texto = termo.to_s.squish
      digitos = texto.gsub(/\D/, "")
      relacao = where("rh_pessoas.nome LIKE :nome OR rh_pessoas.email LIKE :email",
                      nome: "%#{sanitize_sql_like(texto.upcase)}%", email: "%#{sanitize_sql_like(texto.downcase)}%")
      digitos.length >= 3 ? relacao.or(where("rh_pessoas.cpf LIKE ?", "%#{digitos}%")) : relacao
    }

    def self.cpf_valido?(cpf)
      digitos = cpf.to_s.gsub(/\D/, "")
      return false unless digitos.length == 11 && digitos.chars.uniq.size > 1

      numeros = digitos.chars.map(&:to_i)
      [ 9, 10 ].all? do |posicao|
        soma = numeros.first(posicao).each_with_index.sum { |numero, indice| numero * (posicao + 1 - indice) }
        ((soma * 10) % 11) % 10 == numeros[posicao]
      end
    end

    def lotacoes_ativas = lotacoes.ativo.includes(:unidade, :funcao)

    private

    def nome_e_sobrenome
      errors.add(:nome, "deve ter nome e sobrenome") if nome.present? && nome.split.size < 2
    end

    def cpf_valido
      errors.add(:cpf, :invalid) if cpf.present? && !self.class.cpf_valido?(cpf)
    end

    def celular_valido
      errors.add(:celular, "deve ter DDD e número (10 ou 11 dígitos)") if celular.present? && !celular.length.in?(10..11)
    end
  end
end
