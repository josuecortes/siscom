class AddTipoUnidadeToUnidade < ActiveRecord::Migration[6.0]
  def change
    add_reference :unidades, :tipo_unidade, null: false, foreign_key: true
  end
end
