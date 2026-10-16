# Auditoria (porta de audit_logs do seed): quem fez o quê, em quê e quando.
# Registros só são inseridos; nunca alterados nem apagados.
class CreateCoreRegistrosAuditoria < ActiveRecord::Migration[8.1]
  def change
    create_table :core_registros_auditoria do |t|
      t.string :modulo, null: false
      t.string :evento, null: false
      t.references :ator, foreign_key: { to_table: :users }
      t.string :ator_nome
      t.string :alvo_tipo
      t.bigint :alvo_id
      t.string :alvo_descricao
      t.jsonb :dados, null: false, default: {}
      t.string :ip
      t.string :request_id
      t.datetime :created_at, null: false

      t.index :created_at
      t.index [ :modulo, :evento ]
      t.index [ :alvo_tipo, :alvo_id ]
    end
  end
end
