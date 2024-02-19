class CreateTransporteEscolarTransportadores < ActiveRecord::Migration[6.0]
  def change
    create_table :transporte_escolar_transportadores do |t|
      t.string :tipo
      t.string :nome
      t.string :cpf
      t.string :razao_social
      t.string :cnpj
      t.references :municipio, null: false, foreign_key: { to_table: :transporte_escolar_municipios }
      t.string :bairro
      t.string :logradouro
      t.string :numero
      t.string :cep

      t.timestamps
    end
  end
end
