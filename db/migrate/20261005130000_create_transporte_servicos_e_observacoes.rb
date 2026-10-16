# Serviço do motorista e observações (porta de transport_services, transport_request_participations e
# transport_request_observations do seed). Aqui cada trecho (ida ou busca) de uma solicitação é uma
# linha de transporte_servicos, com motorista, veículo e odômetros: serve de serviço e de participação.
class CreateTransporteServicosEObservacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :transporte_servicos do |t|
      t.references :solicitacao, null: false, foreign_key: { to_table: :transporte_solicitacoes }
      t.string :trecho, null: false, default: "ida"
      t.references :motorista, null: false, foreign_key: { to_table: :users }
      t.string :motorista_nome, null: false
      t.references :veiculo, null: false, foreign_key: { to_table: :transporte_veiculos }
      t.string :placa, null: false
      t.bigint :odometro_inicial, null: false
      t.bigint :odometro_final
      t.datetime :iniciado_em, null: false
      t.datetime :finalizado_em
      t.timestamps

      # Um veículo só pode estar em um trecho aberto por vez; uma solicitação também.
      t.index :veiculo_id, unique: true, where: "finalizado_em IS NULL", name: "idx_transporte_servicos_veiculo_em_uso"
      t.index :solicitacao_id, unique: true, where: "finalizado_em IS NULL", name: "idx_transporte_servicos_solicitacao_em_uso"
    end

    create_table :transporte_observacoes do |t|
      t.references :solicitacao, null: false, foreign_key: { to_table: :transporte_solicitacoes }
      t.references :autor, null: false, foreign_key: { to_table: :users }
      t.string :autor_nome, null: false
      t.string :papel, null: false
      t.text :corpo, null: false
      t.timestamps
    end

    add_column :transporte_solicitacoes, :concluida_em, :datetime
  end
end
