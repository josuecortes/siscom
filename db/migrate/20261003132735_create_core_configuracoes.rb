# Configurações do sistema e marca (porta de system_settings do seed). Uma única linha.
class CreateCoreConfiguracoes < ActiveRecord::Migration[8.1]
  def change
    create_table :core_configuracoes do |t|
      t.string :nome_marca_web, null: false, default: "Siscom"
      t.string :nome_marca_celular, null: false, default: "Siscom"
      t.boolean :mostrar_nome_marca_web, null: false, default: true
      t.boolean :mostrar_nome_marca_celular, null: false, default: true
      t.boolean :mostrar_icone_marca_web, null: false, default: true
      t.boolean :mostrar_icone_marca_celular, null: false, default: true
      t.string :nome_cabecalho_web, null: false, default: "Siscom"
      t.string :nome_cabecalho_celular, null: false, default: "Siscom"
      t.boolean :mostrar_nome_cabecalho_web, null: false, default: true
      t.boolean :mostrar_nome_cabecalho_celular, null: false, default: true
      t.string :titulo_login, null: false, default: "Seed"
      t.boolean :mostrar_titulo_login, null: false, default: true
      t.timestamps
    end
  end
end
