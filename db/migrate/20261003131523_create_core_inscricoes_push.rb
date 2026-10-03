# Inscrições de notificação push (Web Push): uma por usuário e aparelho/navegador.
class CreateCoreInscricoesPush < ActiveRecord::Migration[8.1]
  def change
    create_table :core_inscricoes_push do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :p256dh, null: false
      t.string :auth, null: false
      t.string :aparelho
      t.datetime :ultimo_envio_em
      t.timestamps

      t.index :endpoint, unique: true
    end
  end
end
