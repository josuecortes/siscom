class AlterTypeOfProcedencia < ActiveRecord::Migration[6.0]
  def up
    change_column :transporte_escolar_veiculos, :procedencia, 'integer USING CAST(tipo AS integer)'
  end

  def down
    change_column :transporte_escolar_veiculos, :procedencia, :string
  end
end
