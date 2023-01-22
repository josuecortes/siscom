class CreateRequisicaoTransportes < ActiveRecord::Migration[6.0]
  def change
    create_table :requisicao_transportes do |t|
      t.integer :status
      t.references :user, null: false, foreign_key: true
      t.references :unidade, null: false, foreign_key: true
      t.integer :tipo
      t.string :documento_viagem
      t.datetime :data_hora_ida
      t.datetime :data_hora_retorno
      t.text :motivo

      t.timestamps
    end
  end
end
