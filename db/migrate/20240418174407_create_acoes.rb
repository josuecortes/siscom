class CreateAcoes < ActiveRecord::Migration[6.0]
  def change
    create_table :acoes do |t|
      t.string :nome
      t.string :descricao
      t.date :inicio
      t.date :fim
      t.string :motivacao
      t.string :orcamento
      t.integer :status
      t.boolean :mostrar_no_site

      t.timestamps
    end
  end
end
