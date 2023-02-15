class CreateMensagens < ActiveRecord::Migration[6.0]
  def change
    create_table :mensagens do |t|
      t.string :status
      t.text :texto
      t.references :user, null: false, foreign_key: true
      t.references :requisicao_ti, null: false, foreign_key: true

      t.timestamps
    end
  end
end
