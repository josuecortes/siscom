class AddCodigoKitAndContratoToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :codigo_kit, :string
    add_column :equipamentos, :contrato, :string
    
    # Adicionar índices para melhor performance
    add_index :equipamentos, :codigo_kit
    add_index :equipamentos, :contrato
  end
end
