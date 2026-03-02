class AddProdocInstituicaoExternaToRequisicaoTis < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :prodoc_nome_da_instituicao_externa, :string, limit: 140
    add_column :requisicao_tis, :prodoc_sigla_da_instituicao_externa, :string, limit: 30
    add_column :requisicao_tis, :prodoc_nome_unidade_organizacional_externa, :string, limit: 140
    add_column :requisicao_tis, :prodoc_sigla_unidade_organizacional_externa, :string, limit: 30
    add_column :requisicao_tis, :prodoc_responsavel_instituicao_externa, :string, limit: 140
    add_column :requisicao_tis, :prodoc_cargo_do_responsavel_instituicao_externa, :string, limit: 140
    add_column :requisicao_tis, :prodoc_pronome_responsavel_instituicao_externa, :string, limit: 100
    add_column :requisicao_tis, :prodoc_cep_instituicao_externa, :string
    add_column :requisicao_tis, :prodoc_cidade_instituicao_externa, :string
    add_column :requisicao_tis, :prodoc_uf_instituicao_externa, :string
  end
end
