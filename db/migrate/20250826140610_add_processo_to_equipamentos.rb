class AddProcessoToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :processo, :string
  end
end
