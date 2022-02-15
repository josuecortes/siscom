class CreateMotoristas < ActiveRecord::Migration[6.0]
  def change
    create_table :motoristas do |t|
      t.string :nome
      t.string :cpf
      t.date :data_nascimento
      t.string :cnh
      t.date :validade_cnh
      t.string :celular

      t.timestamps
    end
  end
end
