class ModifyEtapasTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :etapas, :indice, :float

    rename_column :etapas, :fim, :termino
  end
end
