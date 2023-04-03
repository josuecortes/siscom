class Unidade < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :requisicao_tis, dependent: :restrict_with_error

  belongs_to :tipo_unidade
  validates_presence_of :nome, :tipo_unidade_id
  validates_presence_of :sigla #if tipo_unidade sede

  before_validation :verificar_tipo_de_unidade
  before_validation :verificar_sigla_de_unidade

  def verificar_tipo_de_unidade
    unless self.tipo_unidade
      sede = TipoUnidade.where(nome: 'SEDE').first
      self.tipo_unidade = sede
    end
  end

  def verificar_sigla_de_unidade
    unless self.sigla
      escola = TipoUnidade.where(nome: 'ESCOLA').first
      if self.tipo_unidade == escola
        self.sigla = 'ESCOLA'
      end 
    end
  end

  def sigla_nome
    "#{self.sigla} - #{self.nome}"
  end
end
