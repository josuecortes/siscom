class CreateItemMovimentacoes < ActiveRecord::Migration[6.0]
  def change
    create_table :item_movimentacoes do |t|
      t.references :movimentacao_equipamento, null: false, foreign_key: true
      t.references :equipamento, null: false, foreign_key: true
      t.boolean :recebido, default: false
      t.datetime :data_recebimento

      t.timestamps
    end
  end
end
