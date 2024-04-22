class CreateTarefas < ActiveRecord::Migration[6.0]
  def change
    create_table :tarefas do |t|
      t.string :titulo
      t.string :descricao
      t.datetime :inicio
      t.datetime :fim
      t.integer :tipo
      t.integer :status
      t.references :etapa, null: true, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
