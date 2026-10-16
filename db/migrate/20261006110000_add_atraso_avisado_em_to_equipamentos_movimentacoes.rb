# Empréstimo/cautela com a devolução vencida: guarda quando o aviso de atraso foi enviado, para avisar uma vez só
# (Equipamentos::AlertasJob). Só acrescenta a coluna.
class AddAtrasoAvisadoEmToEquipamentosMovimentacoes < ActiveRecord::Migration[8.1]
  def change
    add_column :equipamentos_movimentacoes, :atraso_avisado_em, :datetime
  end
end
