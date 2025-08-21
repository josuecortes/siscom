class AddNewFieldsToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :tipo_equipamento, :string
    add_column :equipamentos, :identificacao_kit, :string
    
    add_index :equipamentos, :tipo_equipamento
    add_index :equipamentos, :identificacao_kit
  end
end
