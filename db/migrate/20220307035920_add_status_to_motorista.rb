class AddStatusToMotorista < ActiveRecord::Migration[6.0]
  def change
    add_column :motoristas, :status, :integer
  end
end
