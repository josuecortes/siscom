class AddNewRoles < ActiveRecord::Migration[6.0]
  def change
    Role.create([ {name: 'ges_tp_es'}, {name: 'tec_tp_es'} ])
  end
end
