# Fontes de referência (porta de reference_sources do seed): catálogos publicados
# que alimentam campos de busca/seleção de qualquer módulo.
class CreateCoreFontesReferencia < ActiveRecord::Migration[8.1]
  def change
    create_table :core_fontes_referencia do |t|
      t.string :chave, null: false
      t.string :nome, null: false
      t.text :descricao
      t.string :modulo, null: false        # módulo dono da entidade
      t.string :entidade, null: false      # ex.: "usuarios"
      t.string :campo_rotulo, null: false
      t.string :campo_valor, null: false, default: "id"
      t.string :campo_subtitulo
      t.string :campos_busca, array: true, null: false, default: []
      t.string :tipos_de_campo, array: true, null: false, default: []
      t.string :status, null: false, default: "ativo"
      t.boolean :gerenciada_pelo_sistema, null: false, default: false
      t.timestamps

      t.index :chave, unique: true
    end
  end
end
