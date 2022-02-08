class CreateFuncoes < ActiveRecord::Migration[6.0]
  def change
    create_table :funcoes do |t|
      t.string :nome

      t.timestamps
    end
  end
end
