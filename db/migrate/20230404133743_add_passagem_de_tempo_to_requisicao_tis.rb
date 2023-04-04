class AddPassagemDeTempoToRequisicaoTis < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :data_hora_em_atendimento, :datetime
    add_column :requisicao_tis, :data_hora_concluida, :datetime
    add_column :requisicao_tis, :data_hora_finalizada, :datetime
  end
end
