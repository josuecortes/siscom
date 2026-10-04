# Solicitações do catálogo da TI (porta de helpdesk_problems e dos vínculos com perfis de abertura
# e grupos técnicos). Na tela o nome é "solicitação". Sem "tipo de problema": a solicitação fica
# direto na categoria (decisão do Josue em 2026-10-04).
class CreateTiProblemas < ActiveRecord::Migration[8.1]
  def change
    # Perfil padrão: vale para todo usuário, sem precisar incluir um por um.
    add_column :ti_perfis_abertura, :padrao, :boolean, null: false, default: false

    create_table :ti_problemas do |t|
      t.references :categoria, null: false, foreign_key: { to_table: :ti_categorias }
      t.string :nome, null: false
      t.text :descricao
      t.string :status, null: false, default: "ativo"
      t.string :prioridade_padrao, null: false, default: "normal"
      t.boolean :exige_triagem, null: false, default: true
      t.boolean :permite_varios_abertos, null: false, default: false
      t.bigint :legacy_id
      t.timestamps

      t.index "categoria_id, lower(nome)", unique: true, name: "idx_ti_problemas_categoria_nome"
      t.index :legacy_id, unique: true
    end

    # Quais perfis de abertura podem abrir a solicitação.
    create_table :ti_problemas_perfis do |t|
      t.references :problema, null: false, foreign_key: { to_table: :ti_problemas }
      t.references :perfil_abertura, null: false, foreign_key: { to_table: :ti_perfis_abertura }
      t.timestamps

      t.index %i[problema_id perfil_abertura_id], unique: true
    end

    # Quais grupos técnicos triam e atendem a solicitação.
    create_table :ti_problemas_grupos do |t|
      t.references :problema, null: false, foreign_key: { to_table: :ti_problemas }
      t.references :grupo_tecnico, null: false, foreign_key: { to_table: :ti_grupos_tecnicos }
      t.timestamps

      t.index %i[problema_id grupo_tecnico_id], unique: true
    end
  end
end
