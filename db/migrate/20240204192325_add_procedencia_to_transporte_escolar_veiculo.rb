class AddProcedenciaToTransporteEscolarVeiculo < ActiveRecord::Migration[6.0]
  def change
    add_column :transporte_escolar_veiculos, :procedencia, :string
  end
end
