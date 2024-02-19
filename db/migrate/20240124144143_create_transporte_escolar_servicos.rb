class CreateTransporteEscolarServicos < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_servicos do |t|
      t.string :numero
      t.integer :diarias
      t.references :contrato, null: false, foreign_key: { to_table: :transporte_escolar_contratos }
      t.integer :status
      t.string :ano_mes

      t.timestamps
    end
  end
end
