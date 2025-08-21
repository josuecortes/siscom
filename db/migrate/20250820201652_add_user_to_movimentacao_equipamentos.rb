class AddUserToMovimentacaoEquipamentos < ActiveRecord::Migration[6.0]
  def change
    add_reference :movimentacao_equipamentos, :user, null: true, foreign_key: { to_table: :users }
    
    # Atualizar registros existentes com um usuário padrão (primeiro admin)
    reversible do |dir|
      dir.up do
        if MovimentacaoEquipamento.where(user_id: nil).exists?
          admin_user = User.joins(:roles).where(roles: { name: 'admin' }).first
          if admin_user
            MovimentacaoEquipamento.where(user_id: nil).update_all(user_id: admin_user.id)
          end
        end
        
        # Agora tornar a coluna not null
        change_column_null :movimentacao_equipamentos, :user_id, false
      end
    end
  end
end
