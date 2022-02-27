class CreateDestinos < ActiveRecord::Migration[6.0]
  def change
    create_table :destinos do |t|
      t.string :tipo
      t.text :descricao
      t.string :cep
      t.integer :numero
      t.string :cidade
      t.string :bairro
      t.string :logradouro
      t.references :requisicao_transporte, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
