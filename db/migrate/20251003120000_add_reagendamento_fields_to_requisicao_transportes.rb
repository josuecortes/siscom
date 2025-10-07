class AddReagendamentoFieldsToRequisicaoTransportes < ActiveRecord::Migration[6.0]
  def change
    add_reference :requisicao_transportes, :usuario_reagendou, foreign_key: { to_table: :users }
    add_column :requisicao_transportes, :data_hora_reagendou, :datetime

    add_column :requisicao_transportes, :data_hora_ida_antiga, :datetime
    add_column :requisicao_transportes, :data_hora_retorno_antiga, :datetime

    add_reference :requisicao_transportes, :usuario_aceitou_negou_reagendamento, foreign_key: { to_table: :users }, index: { name: 'idx_rt_usr_anr_id' }
    add_column :requisicao_transportes, :data_hora_aceitou_negou_reagendamento, :datetime

    add_column :requisicao_transportes, :motivo_reagendamento, :text
    add_column :requisicao_transportes, :motivo_negacao_reagendamento, :text

    add_column :requisicao_transportes, :requisicao_reagendada, :boolean, default: false
  end
end

