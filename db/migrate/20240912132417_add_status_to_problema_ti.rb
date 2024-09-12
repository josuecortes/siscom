class AddStatusToProblemaTi < ActiveRecord::Migration[6.0]
  def change
    add_column :problema_tis, :status, :boolean, default: true
  end
end
