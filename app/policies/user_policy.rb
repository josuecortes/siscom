class UserPolicy < ApplicationPolicy
  
  def index?
    user.has_any_role? :master, :admin
  end

  class Scope < Scope
    def resolve
      if user.has_role?(:master)
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
