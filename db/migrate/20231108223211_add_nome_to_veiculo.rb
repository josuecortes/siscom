class AddNomeToVeiculo < ActiveRecord::Migration[6.0]
  def change
    add_column :veiculos, :nome, :string
  end
end
