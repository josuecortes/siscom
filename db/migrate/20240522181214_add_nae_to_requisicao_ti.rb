class AddNaeToRequisicaoTi < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :nae, :string
  end
end