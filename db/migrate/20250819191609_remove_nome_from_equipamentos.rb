class RemoveNomeFromEquipamentos < ActiveRecord::Migration[6.0]
  def change
    remove_column :equipamentos, :nome, :string
  end
end
