class AddNovasRoles < ActiveRecord::Migration[6.0]
  def change
    Role.create([ {name: 'ges_acao'}, {name: 'vis_acao_un'}, {name: 'part_acao'}, {name: 'ges_tf_un'} ])
  end
end
