class AddCreatedByToTarefas < ActiveRecord::Migration[6.0]
  def change
    add_reference :tarefas, :created_by, foreign_key: { to_table: :users }, index: true
  end
end
