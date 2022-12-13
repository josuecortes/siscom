class AlterTableRequisicaoTi < ActiveRecord::Migration[6.0]
  def change
    change_column :requisicao_tis, :tecnico_id, :bigint, null: true
  end
end
