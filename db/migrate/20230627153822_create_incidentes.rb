class CreateIncidentes < ActiveRecord::Migration[6.0]
  def change
    create_table :incidentes do |t|
      t.string :descricao
      t.string :texto_explicativo
      t.string :previsao_de_retorno
      t.datetime :data_hora_inicio
      t.datetime :data_hora_fim
      t.boolean :ativo

      t.timestamps
    end
  end
end
