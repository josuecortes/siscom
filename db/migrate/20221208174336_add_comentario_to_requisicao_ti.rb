class AddComentarioToRequisicaoTi < ActiveRecord::Migration[6.0]
  def change
    add_column :requisicao_tis, :comentario, :text
  end
end
