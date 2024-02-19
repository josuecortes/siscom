class CreateTransporteEscolarVeiculos < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_veiculos do |t|
      t.integer :tipo
      t.string :identificacao
      t.string :ano
      t.string :modelo
      t.string :marca
      t.integer :capacidade_pessoas
      t.integer :capacidade_carga
      t.references :transportador, null: false, foreign_key: { to_table: :transporte_escolar_transportadores }
      t.references :condutor, null: false, foreign_key: { to_table: :transporte_escolar_condutores }

      t.timestamps
    end
  end
end
