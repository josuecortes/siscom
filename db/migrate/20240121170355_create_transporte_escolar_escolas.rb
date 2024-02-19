class CreateTransporteEscolarEscolas < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_escolas do |t|
      t.string :codigo
      t.string :nome
      t.references :municipio, null: false, foreign_key: { to_table: :transporte_escolar_municipios }
      t.string :bairro
      t.string :logradouro
      t.string :numero
      t.string :cep

      t.timestamps
    end
  end
end
