class CreateEtapaUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :etapa_users do |t|
      t.references :etapa, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
