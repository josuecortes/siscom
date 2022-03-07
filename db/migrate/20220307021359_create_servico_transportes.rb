class CreateServicoTransportes < ActiveRecord::Migration[6.0]
  def change
    create_table :servico_transportes do |t|
      t.references :requisicao_transporte, null: false, foreign_key: true
      t.references :veiculo, null: false, foreign_key: true
      t.references :motorista, null: false, foreign_key: true
      t.integer :status
      t.integer :km_inicial
      t.integer :km_final
      t.text :observacoes

      t.timestamps
    end
  end
end
