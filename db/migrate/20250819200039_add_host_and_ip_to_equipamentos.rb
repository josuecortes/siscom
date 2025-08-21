class AddHostAndIpToEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_column :equipamentos, :host, :string
    add_column :equipamentos, :ip, :string
  end
end
