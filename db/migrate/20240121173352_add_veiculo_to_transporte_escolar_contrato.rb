class AddVeiculoToTransporteEscolarContrato < ActiveRecord::Migration[6.0]
  def change
    add_reference :transporte_escolar_contratos, :veiculo, null: false, foreign_key: { to_table: :transporte_escolar_contratos }
  end
end
