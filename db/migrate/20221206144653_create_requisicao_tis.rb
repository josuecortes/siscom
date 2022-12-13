class CreateRequisicaoTis < ActiveRecord::Migration[6.0]
  def change
    create_table :requisicao_tis do |t|
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.references :departamento, null: false, foreign_key: true
      t.references :problema_ti, null: false, foreign_key: true
      t.references :tecnico, null: true, foreign_key: { to_table: :users }
      t.text :observacoes
      t.text :solucao
      t.integer :avaliacao

      t.timestamps
    end
  end
end
