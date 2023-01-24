class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  
  belongs_to :resource,
             :polymorphic => true,
             :optional => true
  

  validates :resource_type,
            :inclusion => { :in => Rolify.resource_types },
            :allow_nil => true
  validates_presence_of :name
  validates_uniqueness_of :name


  scopify

  def exibition_name
    case name
    when 'master'
      "Master"
    when 'admin'
      "Administrador"
    when 'user'
      "Usuário"
    when 'tec_serv_ti'
      "Técnico de TI"
    when 'tec_serv_tp'
      "Técnico de Transporte"
    when 'tec_serv_md'
      "Técnico de requisições de Mídia"
    when 'req_serv_ti'
      "Requisitante de serviços de TI"
    when 'req_serv_ti_sis'
      "Requisitante de serviços de TI - SISTEMAS"  
    when 'req_serv_tp'
      "Requisitante de serviços de Transporte"
    when 'req_serv_md'
      "Requisitante de serviços de Mídia"
    end
  end

  def self.autorizado(u)
    if u.has_role?(:master)
      all
    elsif u.has_role?(:admin)
      where('name != ?', 'master')
    else
      where('name != ? and name != ?', 'master', 'admin')
    end
  end 

end
