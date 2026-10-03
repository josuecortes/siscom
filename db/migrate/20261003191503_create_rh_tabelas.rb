# Módulo RH (porta de people, organizational_units, assignments... do seed).
# `legacy_id` guarda o id da tabela antiga do siscom de onde o registro foi importado.
class CreateRhTabelas < ActiveRecord::Migration[8.1]
  def change
    tabela_de_referencia :rh_tipos_unidade, descricao: true, legacy: true
    tabela_de_referencia :rh_tipos_local, descricao: true
    tabela_de_referencia :rh_cargos, legacy: true
    tabela_de_referencia :rh_funcoes, descricao: true, legacy: true
    tabela_de_referencia :rh_tipos_vinculo

    create_table :rh_unidades do |t|
      t.string :nome, null: false
      t.string :sigla
      t.references :tipo_unidade, null: false, foreign_key: { to_table: :rh_tipos_unidade }
      t.references :tipo_local, foreign_key: { to_table: :rh_tipos_local }
      t.references :pai, foreign_key: { to_table: :rh_unidades }
      t.string :status, null: false, default: "ativo"
      t.bigint :legacy_id
      t.timestamps

      t.index "lower(sigla)", unique: true, where: "sigla IS NOT NULL", name: "idx_rh_unidades_sigla"
      t.index :legacy_id, unique: true
    end

    create_table :rh_dados_escola do |t|
      t.references :unidade, null: false, foreign_key: { to_table: :rh_unidades }, index: { unique: true }
      t.string :nae
      t.string :codigo_inep
      t.text :endereco
      t.timestamps
    end

    create_table :rh_pessoas do |t|
      t.references :user, foreign_key: true, index: { unique: true }
      t.string :nome, null: false
      t.string :email, null: false
      t.string :celular
      t.string :cpf
      t.date :data_nascimento
      t.string :sexo, null: false, default: "nao_informado"
      t.timestamps

      t.index "lower(email)", unique: true, name: "idx_rh_pessoas_email"
      t.index :cpf, unique: true, where: "cpf IS NOT NULL"
    end

    create_table :rh_vinculos do |t|
      t.references :pessoa, null: false, foreign_key: { to_table: :rh_pessoas }, index: { unique: true }
      t.references :tipo_vinculo, null: false, foreign_key: { to_table: :rh_tipos_vinculo }
      t.references :cargo, null: false, foreign_key: { to_table: :rh_cargos }
      t.date :data_inicio, null: false
      t.timestamps
    end

    create_table :rh_lotacoes do |t|
      t.references :pessoa, null: false, foreign_key: { to_table: :rh_pessoas }
      t.references :unidade, null: false, foreign_key: { to_table: :rh_unidades }
      t.references :funcao, null: false, foreign_key: { to_table: :rh_funcoes }
      t.date :data_inicio, null: false
      t.date :data_fim
      t.string :status, null: false, default: "ativo"
      t.datetime :lotado_em, null: false
      t.string :lotado_por_nome
      t.string :lotado_por_email
      t.datetime :encerrado_em
      t.string :encerrado_por_nome
      t.string :encerrado_por_email
      t.timestamps

      # Uma lotação ativa por pessoa, unidade e função.
      t.index %i[pessoa_id unidade_id funcao_id], unique: true, where: "status = 'ativo'", name: "idx_rh_lotacoes_ativa"
    end
  end

  private

  def tabela_de_referencia(nome, descricao: false, legacy: false)
    create_table nome do |t|
      t.string :nome, null: false
      t.text :descricao if descricao
      t.string :status, null: false, default: "ativo"
      t.bigint :legacy_id if legacy
      t.timestamps

      t.index "lower(nome)", unique: true, name: "idx_#{nome}_nome"
      t.index :legacy_id, unique: true if legacy
    end
  end
end
