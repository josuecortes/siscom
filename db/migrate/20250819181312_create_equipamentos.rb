class CreateEquipamentos < ActiveRecord::Migration[6.0]
  def change
    create_table :equipamentos do |t|
      t.string :nome, null: false
      t.string :tipo, null: false
      t.text :descricao
      t.string :marca
      t.string :modelo
      t.string :numero_serial
      t.string :numero_patrimonio
      t.string :outra_identificacao
      t.integer :status, default: 0
      t.datetime :data_cadastro
      t.references :unidade, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :itens_kit, default: []
      t.jsonb :historico_movimentacoes, default: []

      t.timestamps
    end

    add_index :equipamentos, :tipo
    add_index :equipamentos, :status
    add_index :equipamentos, :numero_serial
    add_index :equipamentos, :numero_patrimonio
    add_index :equipamentos, :itens_kit, using: :gin
    add_index :equipamentos, :historico_movimentacoes, using: :gin
  end
end
