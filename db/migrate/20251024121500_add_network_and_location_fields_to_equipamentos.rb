class AddNetworkAndLocationFieldsToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :localizacao_fisica, :string
    add_column :equipamentos, :mac, :string
    add_column :equipamentos, :rack, :string
    add_column :equipamentos, :ativo_de_rede, :string

    add_index :equipamentos, :mac, unique: true
  end
end


