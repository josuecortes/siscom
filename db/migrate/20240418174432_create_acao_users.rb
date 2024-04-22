class CreateAcaoUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :acao_users do |t|
      t.integer :nivel
      t.integer :status
      t.date :inicio
      t.date :fim
      t.references :user, null: false, foreign_key: true
      t.references :acao, null: false, foreign_key: true

      t.timestamps
    end
  end
end
