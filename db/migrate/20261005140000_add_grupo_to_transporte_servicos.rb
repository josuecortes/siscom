# Saída em grupo (como no seed): o motorista leva várias solicitações na mesma viagem, com o mesmo
# veículo. Os trechos da mesma viagem têm o mesmo `grupo`. Por isso o veículo deixa de ter índice
# único por trecho aberto (a regra "veículo em uso por outra viagem" fica no service).
class AddGrupoToTransporteServicos < ActiveRecord::Migration[8.1]
  def change
    add_column :transporte_servicos, :grupo, :string
    add_index :transporte_servicos, :grupo
    remove_index :transporte_servicos, name: "idx_transporte_servicos_veiculo_em_uso", column: :veiculo_id, unique: true, where: "finalizado_em IS NULL"
    add_index :transporte_servicos, :veiculo_id, where: "finalizado_em IS NULL", name: "idx_transporte_servicos_veiculo_aberto"
  end
end
