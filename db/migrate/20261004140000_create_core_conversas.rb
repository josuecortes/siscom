# Conversas do Core (porta de chat_threads, chat_participants e chat_messages do seed). Cada
# conversa pertence a um registro de um módulo (ex.: um chamado da TI), que decide quem participa
# e quando ela fica só para leitura.
class CreateCoreConversas < ActiveRecord::Migration[8.1]
  def change
    create_table :core_conversas do |t|
      t.string :modulo, null: false
      t.string :alvo_tipo, null: false
      t.bigint :alvo_id, null: false
      t.string :titulo, null: false
      t.string :url
      t.string :status, null: false, default: "ativa"
      t.string :motivo_leitura
      t.datetime :ultima_mensagem_em
      t.timestamps

      t.index %i[alvo_tipo alvo_id], unique: true
    end

    create_table :core_participantes do |t|
      t.references :conversa, null: false, foreign_key: { to_table: :core_conversas }
      t.references :user, null: false, foreign_key: true
      t.string :papel, null: false, default: "participante"
      t.string :url
      t.boolean :pode_ler, null: false, default: true
      t.boolean :pode_escrever, null: false, default: false
      t.bigint :lida_ate_id
      t.datetime :entrou_em
      t.datetime :saiu_em
      t.timestamps

      t.index %i[conversa_id user_id], unique: true
    end

    create_table :core_mensagens do |t|
      t.references :conversa, null: false, foreign_key: { to_table: :core_conversas }
      t.references :autor, foreign_key: { to_table: :users }
      t.string :autor_nome
      t.string :tipo, null: false, default: "texto"
      t.text :corpo, null: false
      t.timestamps
    end
  end
end
