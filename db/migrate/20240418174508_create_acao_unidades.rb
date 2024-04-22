class CreateAcaoUnidades < ActiveRecord::Migration[6.0]
  def change
    create_table :acao_unidades do |t|
      t.integer :nivel
      t.references :acao, null: false, foreign_key: true
      t.references :unidade, null: false, foreign_key: true

      t.timestamps
    end
  end
end
