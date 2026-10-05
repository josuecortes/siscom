# Motoristas e veículos do Transporte (porta de transport_drivers e transport_vehicles do seed).
# São recadastrados (decisão do Josue): não há importação das tabelas antigas.
class CreateTransporteMotoristasEVeiculos < ActiveRecord::Migration[8.1]
  def change
    create_table :transporte_motoristas do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :nome, null: false
      t.string :cpf, null: false
      t.date :data_nascimento, null: false
      t.string :cnh_numero, null: false
      t.string :cnh_categoria, null: false
      t.date :cnh_validade, null: false
      t.string :status, null: false, default: "ativo"
      t.timestamps

      t.index :cpf, unique: true
      t.index :cnh_numero, unique: true
    end

    create_table :transporte_veiculos do |t|
      t.string :placa, null: false
      t.string :marca, null: false
      t.string :modelo, null: false
      t.integer :ano, null: false
      t.string :cor, null: false
      t.integer :capacidade, null: false
      t.string :combustivel, null: false
      t.decimal :consumo_km_por_litro, precision: 10, scale: 2, null: false
      t.bigint :odometro_atual, null: false, default: 0
      t.string :status, null: false, default: "ativo"
      t.timestamps

      t.index :placa, unique: true
    end
  end
end
