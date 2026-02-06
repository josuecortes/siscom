class CreateTarefaComentarios < ActiveRecord::Migration[6.0]
  def change
    create_table :tarefa_comentarios do |t|
      t.references :tarefa, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :texto, null: false

      t.timestamps
    end

    add_index :tarefa_comentarios, :created_at
  end
end
