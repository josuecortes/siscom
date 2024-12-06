class CleanupDatabase < ActiveRecord::Migration[6.0]
  def up
    # Apagar registros das tabelas
    puts "Deletando registros de AcaoUnidade..."
    AcaoUnidade.delete_all

    puts "Deletando registros de AcaoUser..."
    AcaoUser.delete_all

    puts "Deletando tarefas com etapa_id preenchido..."
    Tarefa.where.not(etapa_id: nil).delete_all

    puts "Deletando registros de Etapa..."
    Etapa.delete_all

    puts "Deletando registros de Acao..."
    Acao.delete_all

    # Excluir as tabelas
    if table_exists?(:acao_unidades)
      puts "Excluindo tabela acao_unidades..."
      drop_table :acao_unidades
    else
      puts "Tabela acao_unidades não encontrada."
    end

    if table_exists?(:acao_users)
      puts "Excluindo tabela acao_users..."
      drop_table :acao_users
    else
      puts "Tabela acao_users não encontrada."
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Esta migração remove dados e tabelas permanentemente."
  end
end
