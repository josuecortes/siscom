class ModifyAcoesTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :acoes, :descricao, :string

    rename_column :acoes, :fim, :termino

    add_reference :acoes, :user, foreign_key: true, index: true

    add_column :acoes, :documento_externo, :string
  end
end
