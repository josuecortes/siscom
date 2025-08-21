class CreateMovimentacaoEquipamentos < ActiveRecord::Migration[6.0]
  def change
    create_table :movimentacao_equipamentos do |t|
      t.references :unidade_origem, null: false, foreign_key: { to_table: :unidades }
      t.references :unidade_destino, null: false, foreign_key: { to_table: :unidades }
      t.references :responsavel, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'em_andamento'
      t.text :descricao
      t.datetime :data_movimentacao, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
  end
end
