class CreateProblemaTis < ActiveRecord::Migration[6.0]
  def change
    create_table :problema_tis do |t|
      t.string :nome
      t.text :descricao
      t.references :tipo_problema_ti, null: false, foreign_key: true

      t.timestamps
    end
  end
end
