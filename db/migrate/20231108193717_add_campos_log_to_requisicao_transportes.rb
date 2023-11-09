class AddCamposLogToRequisicaoTransportes < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_transportes, :data_hora_aprovada, :datetime
    add_column :requisicao_transportes, :data_hora_em_servico, :datetime
    add_column :requisicao_transportes, :data_hora_negada, :datetime
    add_column :requisicao_transportes, :data_hora_finalizada, :datetime
    add_column :requisicao_transportes, :motivo_negada, :text
    add_column :requisicao_transportes, :usuario_aprovou, :string
    add_column :requisicao_transportes, :usuario_negou, :string
    add_column :requisicao_transportes, :usuario_em_servico, :string
    add_column :requisicao_transportes, :usuario_finalizou, :string
  end
end
