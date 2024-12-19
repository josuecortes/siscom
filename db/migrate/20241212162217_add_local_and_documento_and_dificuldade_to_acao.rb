class AddLocalAndDocumentoAndDificuldadeToAcao < ActiveRecord::Migration[6.0]
  def change
    add_column :acoes, :local, :string
    add_column :acoes, :documento, :string
    add_column :acoes, :complexidade, :string
  end
end
