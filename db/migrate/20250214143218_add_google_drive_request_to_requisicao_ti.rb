class AddGoogleDriveRequestToRequisicaoTi < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :permissao_drive, :text
    add_column :requisicao_tis, :nome_arquivo, :text
  end
end
