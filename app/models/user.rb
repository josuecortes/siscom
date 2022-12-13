class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :funcao
  belongs_to :departamento
  has_one_attached :avatar

  has_many :requisicao_transportes
  has_many :requisicao_tis
  has_many :atendimento_tis, class_name: 'RequisicaoTi', inverse_of: 'tecnico'

  validates_presence_of :nome, :departamento_id, :funcao_id
  validates_uniqueness_of :nome
  validate :verificar_roles_padrao

  before_validation :novo_usuario, on: :create

  def verificar_roles_padrao
    unless self.has_role? :user
      self.errors.add(:role, "A permissão ( Usuário ) deve estar selecionada")
    end
    unless self.has_role? :req_serv_ti
      self.errors.add(:role, "A permissão ( Requisitante de serviços de TI ) deve estar selecionada")
    end
  end 
  

  def novo_usuario
    self.password = "@seed123"
    self.password_confirmation = "@seed123"
    # self.add_role(:user) unless self.roles.include? :user
    # self.add_role(:req_serv_ti) unless self.roles.include? :req_serv_ti
  end

  # Roles
  # :user           => Usuario do sistema
  # :admin          => Administrador do sistema
  # :tec_serv_ti    => Tecnico de requisicoes de Tecnologia da Informacao
  # :tec_serv_tp    => Tecnico de requisicoes de Transporte
  # :tec_serv_md    => Tecnico de requisicoes de Midia
  # :req_serv_ti    => Requisitante de servico de Tecnologia da Informacao
  # :req_serv_tp    => Requisitante de servico de Transporte
  # :req_serv_md    => Requisitante de servico de Midia

  def self.autorizado(u)
    if u.has_role?(:master)
      all
    elsif u.has_role?(:admin)
      where.not(id: User.with_role(:master))
    else
      where(id: u.id)
    end
  end 

  def pode_solicitar_requisicao_ti
    return false if self.requisicao_tis.where(status: [1, 2, 3]).any?
    
    true
  end
end
