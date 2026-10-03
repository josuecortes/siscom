# Permissões por módulo (02-arquitetura-e-convencoes.md, seção 5):
# core_acessos    = o usuário entra (ou está bloqueado) no módulo;
# core_concessoes = o usuário tem o papel X no módulo, com escopo opcional.
class CreateCoreAcessosEConcessoes < ActiveRecord::Migration[8.1]
  def change
    create_table :core_acessos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :modulo, null: false
      t.string :status, null: false, default: "ativo"
      t.timestamps

      t.index [ :user_id, :modulo ], unique: true
    end

    create_table :core_concessoes do |t|
      t.references :acesso, null: false, foreign_key: { to_table: :core_acessos }
      t.references :user, null: false, foreign_key: true
      t.string :modulo, null: false
      t.string :papel, null: false
      t.string :escopo_tipo
      t.bigint :escopo_id
      t.string :status, null: false, default: "ativo"
      t.references :concedido_por, foreign_key: { to_table: :users }
      t.timestamps

      # Só uma concessão ativa por usuário, módulo, papel e escopo.
      t.index [ :user_id, :modulo, :papel ], unique: true,
              where: "status = 'ativo' AND escopo_id IS NULL", name: "idx_core_concessoes_ativa_global"
      t.index [ :user_id, :modulo, :papel, :escopo_tipo, :escopo_id ], unique: true,
              where: "status = 'ativo' AND escopo_id IS NOT NULL", name: "idx_core_concessoes_ativa_escopo"
      t.index [ :escopo_tipo, :escopo_id ]
    end
  end
end
