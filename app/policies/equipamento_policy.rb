class EquipamentoPolicy < ApplicationPolicy
  def index?
    user.has_role?(:tec_serv_ti)
  end

  def show?
    user.has_role?(:tec_serv_ti)
  end

  def new?
    user.has_role?(:tec_serv_ti)
  end

  def create?
    user.has_role?(:tec_serv_ti)
  end

  def edit?
    user.has_role?(:tec_serv_ti)
  end

  def update?
    user.has_role?(:tec_serv_ti)
  end

  def destroy?
    user.has_role?(:tec_serv_ti)
  end

  def transferir?
    user.has_role?(:tec_serv_ti)
  end

  def alterar_status?
    user.has_role?(:tec_serv_ti)
  end

  def buscar?
    user.has_role?(:tec_serv_ti)
  end

  def relatorio?
    user.has_role?(:tec_serv_ti)
  end

  def verificar_kit?
    user.has_role?(:tec_serv_ti)
  end

  def remover_de_kit?
    user.has_role?(:tec_serv_ti)
  end

  def exportar_excel?
    user.has_role?(:tec_serv_ti)
  end

  def autocomplete_marcas?
    user.has_role?(:tec_serv_ti)
  end

  def autocomplete_modelos?
    user.has_role?(:tec_serv_ti)
  end

  def autocomplete_identificacoes_kit?
    user.has_role?(:tec_serv_ti)
  end

  def autocomplete_contratos?
    user.has_role?(:tec_serv_ti)
  end

  def autocomplete_processos?
    user.has_role?(:tec_serv_ti)
  end

  class Scope < Scope
    def resolve
      if user.has_role?(:tec_serv_ti)
        scope.all
      else
        scope.none
      end
    end
  end
end
