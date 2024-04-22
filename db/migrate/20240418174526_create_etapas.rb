class CreateEtapas < ActiveRecord::Migration[6.0]
  def change
    create_table :etapas do |t|
      t.float :indice
      t.string :nome
      t.string :descricao
      t.date :inicio
      t.date :fim
      t.integer :status
      t.references :acao, null: false, foreign_key: true

      t.timestamps
    end
  end
end
