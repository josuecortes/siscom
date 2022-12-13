class CreateTipoProblemaTis < ActiveRecord::Migration[6.0]
  def change
    create_table :tipo_problema_tis do |t|
      t.string :nome
      t.text :descricao

      t.timestamps
    end
  end
end
