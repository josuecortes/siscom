# Chamados da TI (porta de helpdesk_tickets, helpdesk_ticket_events e helpdesk_ticket_field_values).
# O chamado guarda um retrato do solicitante e da unidade no momento da abertura.
class CreateTiChamados < ActiveRecord::Migration[8.1]
  def change
    create_table :ti_chamados do |t|
      t.string :codigo
      t.references :problema, null: false, foreign_key: { to_table: :ti_problemas }
      t.string :status, null: false, default: "aberto"
      t.string :prioridade, null: false, default: "normal"
      t.references :solicitante, null: false, foreign_key: { to_table: :users }
      t.string :solicitante_nome, null: false
      t.string :solicitante_email, null: false
      t.bigint :rh_unidade_id
      t.string :unidade_nome
      t.string :funcao_nome
      t.references :triador, foreign_key: { to_table: :users }
      t.references :responsavel, foreign_key: { to_table: :users }
      t.text :nota_triagem
      t.datetime :triado_em
      t.datetime :aberto_em, null: false
      t.datetime :concluido_em
      t.datetime :finalizado_em
      t.integer :avaliacao
      t.boolean :avaliacao_resolvido
      t.text :avaliacao_comentario
      t.timestamps

      t.index :codigo, unique: true
      t.index :status
      t.index :rh_unidade_id
    end

    create_table :ti_eventos_chamado do |t|
      t.references :chamado, null: false, foreign_key: { to_table: :ti_chamados }
      t.string :tipo, null: false
      t.string :de_status
      t.string :para_status
      t.text :nota
      t.references :ator, foreign_key: { to_table: :users }
      t.string :ator_nome
      t.datetime :ocorrido_em, null: false
      t.timestamps
    end

    # Resposta de um campo do formulário. Guarda o nome e o tipo do campo como estavam na abertura.
    create_table :ti_valores_campo do |t|
      t.references :chamado, null: false, foreign_key: { to_table: :ti_chamados }
      t.references :campo_problema, null: false, foreign_key: { to_table: :ti_campos_problema }
      t.string :rotulo, null: false
      t.string :tipo, null: false
      t.text :valor_texto
      t.jsonb :valor_json, null: false, default: {}
      t.timestamps

      t.index %i[chamado_id campo_problema_id], unique: true
    end
  end
end
