class ChangeTipoToIntegerInCondutores < ActiveRecord::Migration[6.0]
  def up
    change_column :transporte_escolar_condutores, :tipo, 'integer USING CAST(tipo AS integer)'
  end

  def down
    change_column :transporte_escolar_condutores, :tipo, :string
  end
end
