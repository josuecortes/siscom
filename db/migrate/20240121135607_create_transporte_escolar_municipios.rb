class CreateTransporteEscolarMunicipios < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_municipios do |t|
      t.string :nome
      t.integer :tipo

      t.timestamps
    end
  end
end
