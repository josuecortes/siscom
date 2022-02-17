class CreateVeiculos < ActiveRecord::Migration[6.0]
  def change
    create_table :veiculos do |t|
      t.string :placa
      t.string :marca
      t.string :modelo
      t.integer :combustivel
      t.integer :capacidade
      t.integer :carga
      t.integer :status

      t.timestamps
    end
  end
end
