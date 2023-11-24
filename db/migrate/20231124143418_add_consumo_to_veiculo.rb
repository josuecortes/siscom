class AddConsumoToVeiculo < ActiveRecord::Migration[6.0]
  def change
    add_column :veiculos, :consumo, :float
  end
end
