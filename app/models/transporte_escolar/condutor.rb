class TransporteEscolar::Condutor < ApplicationRecord
  # fields
  # t.string :nome
  # t.string :cpf
  # t.string :tipo
  # t.string :permissao
  # t.string :vencimento
  # t.references :municipio, null: false, foreign_key: { to_table: :transporte_escolar_municipios }
  # t.string :bairro
  # t.string :logradouro
  # t.string :numero
  # t.string :cep

  belongs_to :municipio, class_name: 'TransporteEscolar::Municipio'

  has_many :veiculos, class_name: "TransporteEscolar::Veiculo", dependent: :restrict_with_error

  validates_presence_of :nome, :cpf, :tipo, :permissao, :municipio_id
  validates_uniqueness_of :cpf

  enum tipo: { "Rodoviário": 1, "Hidroviário": 2 }

  before_save :upcase_fields

  def upcase_fields
    self.nome.upcase! if self.nome
    self.permissao.upcase! if self.permissao
    self.bairro.upcase!
    self.logradouro.upcase!
    self.numero.upcase!
  end
end
