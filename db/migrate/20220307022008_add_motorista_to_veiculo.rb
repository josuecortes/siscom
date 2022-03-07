class AddMotoristaToVeiculo < ActiveRecord::Migration[6.0]
  def change
    add_reference :veiculos, :motorista, null: true, foreign_key: true
  end
end
