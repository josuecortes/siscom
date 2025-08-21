class AddGarantiaToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :garantia, :integer
  end
end
