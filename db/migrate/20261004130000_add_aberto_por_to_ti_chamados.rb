# Chamado aberto pela TI em nome de outra pessoa: guarda quem abriu. O dono continua sendo o solicitante.
class AddAbertoPorToTiChamados < ActiveRecord::Migration[8.1]
  def change
    add_reference :ti_chamados, :aberto_por, foreign_key: { to_table: :users }
  end
end
