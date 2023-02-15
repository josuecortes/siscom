class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :funcao
  belongs_to :unidade
  has_one_attached :avatar

  has_many :requisicao_transportes
  has_many :requisicao_tis
  has_many :atendimento_tis, class_name: 'RequisicaoTi', inverse_of: 'tecnico'
  has_many :mensagens

  validates_presence_of :nome, :unidade_id, :funcao_id
  validates_uniqueness_of :nome
  validate :verificar_roles_padrao

  before_validation :senha_padrao, on: :create

  def verificar_roles_padrao
    unless self.has_role? :user
      self.errors.add(:role, "A permissão ( Usuário ) deve estar selecionada")
    end
    unless self.has_role? :req_serv_ti
      self.errors.add(:role, "A permissão ( Requisitante de serviços de TI ) deve estar selecionada")
    end
  end 
  

  def senha_padrao
    self.password = "Seed@123"
    self.password_confirmation = "Seed@123"
  end

  # Roles
  # :user             => Usuario do sistema
  # :admin            => Administrador do sistema
  # :tec_serv_ti      => Tecnico de requisicoes de Tecnologia da Informacao
  # :tec_serv_ti      => Tecnico de requisicoes de Tecnologia da Informacao Sistemas Tipo Prodoc
  # :tec_serv_tp      => Tecnico de requisicoes de Transporte
  # :tec_serv_md      => Tecnico de requisicoes de Midia
  # :req_serv_ti_sis  => Requisitante de servico de Tecnologia da Informacao
  # :req_serv_tp      => Requisitante de servico de Transporte
  # :req_serv_md      => Requisitante de servico de Midia

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
    return true if self.has_role?(:req_serv_ti_sis)
    
    return false if self.requisicao_tis.where(status: [1, 2, 3]).any?
    
    true
  end

  def pode_solicitar_requisicao_ti_normal
    pode_requisitar_normal = true
    if self.has_role?(:req_serv_ti_sis) 
      self.requisicao_tis.where(status: [1, 2, 3]).each do |r|
        if r.problema_ti.tipo_problema_ti_id != 3
          pode_requisitar_normal = false
        end
      end
    elsif self.has_role?(:req_serv_ti) 
      pode_requisitar_normal = false if self.requisicao_tis.where(status: [1, 2, 3]).any?
    end
    
    return pode_requisitar_normal
  end

  def alterar_senha(params)
    unless params[:current_password] or params[:password] or params[:password_confirmation]
      self.errors.add(:current_password, 'Você deve preencher esse campo')
      return false
    end

    if params[:password] == 'Seed@123' or params[:password] == 'seed@123'
      self.errors.add(:password, 'A nova senha não pode ser (Seed@123)!')
      return false
    end

    unless self.valid_password?(params[:current_password])
      self.errors.add(:current_password, 'A senha atual não confere!')
      return false
    end

    if params[:password] != params[:password_confirmation]
      self.errors.add(:password_confirmation, 'A confirmação da senha não é igual a nova senha!')
      return false
    end

    self.password = params[:password]
    self.password_confirmation = params[:password_confirmation]
    if self.save
      return true
    end

    return false
  end

  def resetar_senha
    senha_padrao
    if self.save
      return true
    end

    return false
  end

  def pode_chatear
    return true if self.requisicao_tis.where(status: [2]).any?

    return true if self.has_role? :tec_serv_ti

    false
  end

  def mensagens_nao_lidas
    mensagens = 0
    self.requisicao_tis.each do |r|
      mensagens += r.mensagens_nao_lidas(self)
    end

    if self.has_role? :tec_serv_ti
      RequisicaoTi.do_tecnico(self).each do |r|
        mensagens += r.mensagens_nao_lidas(self)
      end
    end

    mensagens
  end
end

