class CreateUnidades < ActiveRecord::Migration[6.0]
  def change
    create_table :unidades do |t|
      t.string :nome
      t.string :sigla

      t.timestamps
    end
  end
end
