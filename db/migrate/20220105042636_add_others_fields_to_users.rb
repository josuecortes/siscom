class AddOthersFieldsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :nome, :string
    add_column :users, :celular, :string
    add_column :users, :cpf, :string
    add_column :users, :data_nascimento, :date
    add_reference :users, :unidade, null: true, foreign_key: true
    add_reference :users, :funcao, null: true, foreign_key: true
  end
end
