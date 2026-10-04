# Módulo TI, base do catálogo (porta de helpdesk_request_categories, helpdesk_opening_profiles,
# helpdesk_technical_groups e dos vínculos com usuários do seed).
class CreateTiCatalogoBase < ActiveRecord::Migration[8.1]
  def change
    item_de_catalogo :ti_categorias, legacy: true
    item_de_catalogo :ti_perfis_abertura
    item_de_catalogo :ti_grupos_tecnicos do |t|
      t.boolean :permite_autoatribuicao, null: false, default: true
    end

    # Quem pode abrir as solicitações de um perfil de abertura.
    create_table :ti_perfis_usuario do |t|
      t.references :perfil_abertura, null: false, foreign_key: { to_table: :ti_perfis_abertura }
      t.references :user, null: false, foreign_key: true
      t.references :concedido_por, foreign_key: { to_table: :users }
      t.timestamps

      t.index %i[perfil_abertura_id user_id], unique: true
    end

    # Quem tria/atende os chamados de um grupo técnico.
    create_table :ti_membros_grupo do |t|
      t.references :grupo_tecnico, null: false, foreign_key: { to_table: :ti_grupos_tecnicos }
      t.references :user, null: false, foreign_key: true
      t.references :concedido_por, foreign_key: { to_table: :users }
      t.timestamps

      t.index %i[grupo_tecnico_id user_id], unique: true
    end
  end

  private

  def item_de_catalogo(nome, legacy: false)
    create_table nome do |t|
      t.string :nome, null: false
      t.text :descricao
      t.string :status, null: false, default: "ativo"
      t.bigint :legacy_id if legacy
      yield t if block_given?
      t.timestamps

      t.index "lower(nome)", unique: true, name: "idx_#{nome}_nome"
      t.index :legacy_id, unique: true if legacy
    end
  end
end
