# Notificações do sistema (porta de notifications do seed).
class CreateCoreNotificacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :core_notificacoes do |t|
      t.references :user, null: false, foreign_key: true # destinatário
      t.references :ator, foreign_key: { to_table: :users }
      t.string :modulo, null: false
      t.string :evento, null: false
      t.string :titulo, null: false
      t.text :mensagem
      t.string :url_acao
      t.string :alvo_tipo
      t.bigint :alvo_id
      t.jsonb :dados, null: false, default: {}
      t.datetime :lida_em
      t.timestamps

      t.index [ :user_id, :lida_em ]
      t.index [ :user_id, :created_at ]
      t.index [ :alvo_tipo, :alvo_id ]
    end
  end
end
