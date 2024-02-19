class CreateTransporteEscolarContratos < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_contratos do |t|
      t.string :codigo
      t.string :rota
      t.text :descricao
      t.date :inicio
      t.date :fim
      t.bigint :valor_total
      t.string :valor_diaria
      t.string :bigint
      t.references :transportador, null: false, foreign_key: { to_table: :transporte_escolar_transportadores }
      t.references :escola, null: false, foreign_key: { to_table: :transporte_escolar_escolas }

      t.timestamps
    end
  end
end
