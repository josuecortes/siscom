class ChangeTarefa < ActiveRecord::Migration[6.0]
  def up
    add_column :tarefas, :prioridade, :integer
    add_column :tarefas, :prazo, :date
  end

  def down
    remove_column :tarefas, :prioridade
    remove_column :tarefas, :prazo
  end
end