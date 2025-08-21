class AddStatusToItemMovimentacoes < ActiveRecord::Migration[6.0]
  def change
    add_column :item_movimentacoes, :status, :string, default: 'pendente'
    
    # Atualizar registros existentes
    reversible do |dir|
      dir.up do
        execute "UPDATE item_movimentacoes SET status = 'pendente' WHERE status IS NULL"
      end
    end
  end
end
