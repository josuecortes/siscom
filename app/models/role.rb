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
    when 'ges_tp_es'
      "Gestor de Transporte Escolar"
    when 'tec_tp_es'
      "Tecnico de Transporte Escolar"
    # when 'ges_acao'
    #   "Gestor de ações"
    # when 'vis_acao_un'
    #   "Visualizador de ações da unidade"
    # when 'part_acao'
    #   "Participante de ações"
    when 'ges_tf_un'
      "Gestor de tarefas da unidade"
    end
  end

  def self.autorizado(u)
    if u.has_role?(:master)
      all
    elsif u.has_role?(:admin)
      where('name != ? and name != ? and name != ?', 'master', 'ges_tp_es', 'tec_tp_es')
    elsif u.has_role?(:tec_serv_tp)
      where('name = ? or name = ?', 'tec_serv_tp', 'req_serv_tp')
    else
      where('name != ? and name != ?', 'master', 'admin')
    end
  end 

end
