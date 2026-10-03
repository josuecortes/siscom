# Pendências encontradas na importação do siscom antigo para o RH (CPF vazio,
# inválido ou repetido, nome sem sobrenome...), para alguém conferir depois.
class CreateRhPendenciasImportacao < ActiveRecord::Migration[8.1]
  def change
    create_table :rh_pendencias_importacao do |t|
      t.references :pessoa, foreign_key: { to_table: :rh_pessoas }
      t.string :tipo, null: false
      t.string :descricao, null: false
      t.datetime :resolvida_em
      t.timestamps

      t.index %i[pessoa_id tipo], unique: true
      t.index :tipo
    end
  end
end
