class TransporteEscolar::Transportador < ApplicationRecord
  attr_accessor :nome_ou_razao_social
  attr_accessor :cpf_ou_cnpj

  belongs_to :municipio, class_name: "TransporteEscolar::Municipio"

  has_many :veiculos, class_name: "TransporteEscolar::Veiculo", dependent: :restrict_with_error

  validates_presence_of :tipo, :municipio_id, :codigo, :conta, :agencia, :tipo_de_conta, :conta
  # validates_presence_of :nome, :cpf, if: -> { tipo == "Pessoa Física" }
  # validates_presence_of :razao_social, :cnpj, if: -> { tipo == "Pessoa Jurídica" }


  validates :tipo, :municipio_id, :codigo, :conta, :agencia, :tipo_de_conta, :conta, presence: true
  
  validates :nome, :cpf, presence: true, if: -> { tipo == "Pessoa Física" }
  validates :cpf, uniqueness: true, length: { is: 14 }, if: -> { tipo == "Pessoa Física" && cpf.present? }
  
  validates :razao_social, :cnpj, presence: true, if: -> { tipo == "Pessoa Jurídica" }
  validates :cnpj, uniqueness: true, length: { is: 18 }, if: -> { tipo == "Pessoa Jurídica" && cnpj.present? }

  enum tipo: { "Pessoa Física": 1,  "Pessoa Jurídica": 2 }
  enum tipo_de_conta: { "Conta Corrente": 1,  "Conta Poupança": 2, "Conta Sálario": 3 }

  before_save :upcase_fields

  def nome_ou_razao_social
    tipo == "Pessoa Física" ? nome : razao_social
  end

  def cpf_ou_cnpj
    tipo == "Pessoa Física" ? cpf : cnpj
  end

  def upcase_fields
    self.nome.upcase! if self.nome
    self.razao_social.upcase! if self.razao_social
    self.codigo.upcase!
    self.banco.upcase!
    self.agencia.upcase!
    self.conta.upcase!
    self.bairro.upcase!
    self.logradouro.upcase!
    self.numero.upcase!
  end
end
