class CreatePassageiros < ActiveRecord::Migration[6.0]
  def change
    create_table :passageiros do |t|
      t.string :nome
      t.string :celular
      t.string :cpf
      t.references :requisicao_transporte, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
