class ChangekmInicialAndKmFinalFromServicoTransporte < ActiveRecord::Migration[6.0]
  def change
    change_column :servico_transportes, :km_inicial, :bigint
    change_column :servico_transportes, :km_final, :bigint
  end
end
