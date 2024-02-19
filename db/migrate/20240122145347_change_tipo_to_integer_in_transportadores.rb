class ChangeTipoToIntegerInTransportadores < ActiveRecord::Migration[6.0]
  def up
    change_column :transporte_escolar_transportadores, :tipo, 'integer USING CAST(tipo AS integer)'
  end

  def down
    change_column :transporte_escolar_transportadores, :tipo, :string
  end
end
