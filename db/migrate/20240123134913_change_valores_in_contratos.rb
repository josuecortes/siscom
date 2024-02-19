class ChangeValoresInContratos < ActiveRecord::Migration[6.0]
  def up
    change_column :transporte_escolar_contratos, :valor_total, 'float USING CAST(valor_total AS float)'
    change_column :transporte_escolar_contratos, :valor_diaria, 'float USING CAST(valor_diaria AS float)'
  end

  def down
    change_column :transporte_escolar_contratos, :valor_total, :bigint
    change_column :transporte_escolar_contratos, :valor_diaria, :bigint
  end
end
