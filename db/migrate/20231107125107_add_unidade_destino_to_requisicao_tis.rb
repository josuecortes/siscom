class AddUnidadeDestinoToRequisicaoTis < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :unidade_destino, :text
  end
end
