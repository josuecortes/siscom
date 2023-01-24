class AddFieldsToRequisicaoTi < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :nome, :string
    add_column :requisicao_tis, :email, :string
    add_column :requisicao_tis, :cpf, :string
    add_column :requisicao_tis, :rg, :string
    add_column :requisicao_tis, :data_nascimento, :date
    add_column :requisicao_tis, :celular, :string
    add_reference :requisicao_tis, :funcao, null: true, foreign_key: true
    add_reference :requisicao_tis, :cargo, null: true, foreign_key: true
    add_column :requisicao_tis, :estado, :string
    add_column :requisicao_tis, :municipio, :string
    add_column :requisicao_tis, :perfil, :string
    add_column :requisicao_tis, :periodo_inicio, :date
    add_column :requisicao_tis, :periodo_fim, :date
  end
end
