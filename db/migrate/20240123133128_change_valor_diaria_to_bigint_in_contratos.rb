class ChangeValorDiariaToBigintInContratos < ActiveRecord::Migration[6.0]
  def up
    change_column :transporte_escolar_contratos, :valor_diaria, 'bigint USING CAST(valor_diaria AS bigint)'
  end

  def down
    change_column :transporte_escolar_contratos, :valor_diaria, :string
  end
end
