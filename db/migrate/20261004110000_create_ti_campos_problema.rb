# Campos do formulário de cada solicitação da TI (porta de helpdesk_problem_fields).
class CreateTiCamposProblema < ActiveRecord::Migration[8.1]
  def change
    create_table :ti_campos_problema do |t|
      t.references :problema, null: false, foreign_key: { to_table: :ti_problemas }
      t.string :chave, null: false
      t.string :rotulo, null: false
      t.string :tipo, null: false, default: "texto"
      t.boolean :obrigatorio, null: false, default: false
      t.integer :posicao, null: false, default: 0
      t.string :exemplo
      t.string :mascara
      t.text :ajuda
      t.jsonb :config, null: false, default: {}
      t.string :status, null: false, default: "ativo"
      t.timestamps

      t.index %i[problema_id chave], unique: true
    end
  end
end
