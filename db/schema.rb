# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_12_02_021523) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "acoes", force: :cascade do |t|
    t.string "nome"
    t.date "inicio"
    t.date "termino"
    t.string "motivacao"
    t.string "orcamento"
    t.integer "status"
    t.boolean "mostrar_no_site"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "user_id"
    t.string "documento_externo"
    t.index ["user_id"], name: "index_acoes_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "cargos", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "destinos", force: :cascade do |t|
    t.string "tipo"
    t.text "descricao"
    t.string "cep"
    t.integer "numero"
    t.string "cidade"
    t.string "bairro"
    t.string "logradouro"
    t.bigint "requisicao_transporte_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["requisicao_transporte_id"], name: "index_destinos_on_requisicao_transporte_id"
    t.index ["user_id"], name: "index_destinos_on_user_id"
  end

  create_table "etapa_users", force: :cascade do |t|
    t.bigint "etapa_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["etapa_id"], name: "index_etapa_users_on_etapa_id"
    t.index ["user_id"], name: "index_etapa_users_on_user_id"
  end

  create_table "etapas", force: :cascade do |t|
    t.string "nome"
    t.string "descricao"
    t.date "inicio"
    t.date "termino"
    t.integer "status"
    t.bigint "acao_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["acao_id"], name: "index_etapas_on_acao_id"
  end

  create_table "etapas_users", force: :cascade do |t|
    t.bigint "etapa_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["etapa_id"], name: "index_etapas_users_on_etapa_id"
    t.index ["user_id"], name: "index_etapas_users_on_user_id"
  end

  create_table "funcoes", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "incidentes", force: :cascade do |t|
    t.string "descricao"
    t.string "texto_explicativo"
    t.string "previsao_de_retorno"
    t.datetime "data_hora_inicio"
    t.datetime "data_hora_fim"
    t.boolean "ativo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "mensagens", force: :cascade do |t|
    t.string "status"
    t.text "texto"
    t.bigint "user_id", null: false
    t.bigint "requisicao_ti_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["requisicao_ti_id"], name: "index_mensagens_on_requisicao_ti_id"
    t.index ["user_id"], name: "index_mensagens_on_user_id"
  end

  create_table "motoristas", force: :cascade do |t|
    t.string "nome"
    t.string "cpf"
    t.date "data_nascimento"
    t.string "cnh"
    t.date "validade_cnh"
    t.string "celular"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
  end

  create_table "passageiros", force: :cascade do |t|
    t.string "nome"
    t.string "celular"
    t.string "cpf"
    t.bigint "requisicao_transporte_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["requisicao_transporte_id"], name: "index_passageiros_on_requisicao_transporte_id"
    t.index ["user_id"], name: "index_passageiros_on_user_id"
  end

  create_table "problema_tis", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.bigint "tipo_problema_ti_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "status", default: true
    t.index ["tipo_problema_ti_id"], name: "index_problema_tis_on_tipo_problema_ti_id"
  end

  create_table "requisicao_tis", force: :cascade do |t|
    t.integer "status"
    t.bigint "user_id", null: false
    t.bigint "unidade_id", null: false
    t.bigint "problema_ti_id", null: false
    t.bigint "tecnico_id"
    t.text "observacoes"
    t.text "solucao"
    t.integer "avaliacao"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "comentario"
    t.string "nome"
    t.string "email"
    t.string "cpf"
    t.string "rg"
    t.date "data_nascimento"
    t.string "celular"
    t.bigint "funcao_id"
    t.bigint "cargo_id"
    t.string "estado"
    t.string "municipio"
    t.string "perfil"
    t.date "periodo_inicio"
    t.date "periodo_fim"
    t.datetime "data_hora_em_atendimento"
    t.datetime "data_hora_concluida"
    t.datetime "data_hora_finalizada"
    t.text "unidade_destino"
    t.string "nae"
    t.index ["cargo_id"], name: "index_requisicao_tis_on_cargo_id"
    t.index ["funcao_id"], name: "index_requisicao_tis_on_funcao_id"
    t.index ["problema_ti_id"], name: "index_requisicao_tis_on_problema_ti_id"
    t.index ["tecnico_id"], name: "index_requisicao_tis_on_tecnico_id"
    t.index ["unidade_id"], name: "index_requisicao_tis_on_unidade_id"
    t.index ["user_id"], name: "index_requisicao_tis_on_user_id"
  end

  create_table "requisicao_transportes", force: :cascade do |t|
    t.integer "status"
    t.bigint "user_id", null: false
    t.bigint "unidade_id", null: false
    t.integer "tipo"
    t.string "documento_viagem"
    t.datetime "data_hora_ida"
    t.datetime "data_hora_retorno"
    t.text "motivo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "data_hora_aprovada"
    t.datetime "data_hora_em_servico"
    t.datetime "data_hora_negada"
    t.datetime "data_hora_finalizada"
    t.text "motivo_negada"
    t.string "usuario_aprovou"
    t.string "usuario_negou"
    t.string "usuario_em_servico"
    t.string "usuario_finalizou"
    t.index ["unidade_id"], name: "index_requisicao_transportes_on_unidade_id"
    t.index ["user_id"], name: "index_requisicao_transportes_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource_type_and_resource_id"
  end

  create_table "servico_transportes", force: :cascade do |t|
    t.bigint "requisicao_transporte_id", null: false
    t.bigint "veiculo_id", null: false
    t.bigint "motorista_id", null: false
    t.integer "status"
    t.bigint "km_inicial"
    t.bigint "km_final"
    t.text "observacoes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["motorista_id"], name: "index_servico_transportes_on_motorista_id"
    t.index ["requisicao_transporte_id"], name: "index_servico_transportes_on_requisicao_transporte_id"
    t.index ["veiculo_id"], name: "index_servico_transportes_on_veiculo_id"
  end

  create_table "tarefas", force: :cascade do |t|
    t.string "titulo"
    t.string "descricao"
    t.datetime "inicio"
    t.datetime "fim"
    t.integer "tipo"
    t.integer "status"
    t.bigint "etapa_id"
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "prioridade"
    t.date "prazo"
    t.index ["etapa_id"], name: "index_tarefas_on_etapa_id"
    t.index ["user_id"], name: "index_tarefas_on_user_id"
  end

  create_table "tipo_problema_tis", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "tipo_unidades", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transporte_escolar_condutores", force: :cascade do |t|
    t.string "nome"
    t.string "cpf"
    t.integer "tipo"
    t.string "permissao"
    t.string "vencimento"
    t.bigint "municipio_id", null: false
    t.string "bairro"
    t.string "logradouro"
    t.string "numero"
    t.string "cep"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["municipio_id"], name: "index_transporte_escolar_condutores_on_municipio_id"
  end

  create_table "transporte_escolar_contratos", force: :cascade do |t|
    t.string "codigo"
    t.string "rota"
    t.text "descricao"
    t.date "inicio"
    t.date "fim"
    t.float "valor_total"
    t.float "valor_diaria"
    t.string "bigint"
    t.bigint "transportador_id", null: false
    t.bigint "escola_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "veiculo_id", null: false
    t.index ["escola_id"], name: "index_transporte_escolar_contratos_on_escola_id"
    t.index ["transportador_id"], name: "index_transporte_escolar_contratos_on_transportador_id"
    t.index ["veiculo_id"], name: "index_transporte_escolar_contratos_on_veiculo_id"
  end

  create_table "transporte_escolar_escolas", force: :cascade do |t|
    t.string "codigo"
    t.string "nome"
    t.bigint "municipio_id", null: false
    t.string "bairro"
    t.string "logradouro"
    t.string "numero"
    t.string "cep"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["municipio_id"], name: "index_transporte_escolar_escolas_on_municipio_id"
  end

  create_table "transporte_escolar_municipios", force: :cascade do |t|
    t.string "nome"
    t.integer "tipo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "transporte_escolar_servicos", force: :cascade do |t|
    t.string "numero"
    t.integer "diarias"
    t.bigint "contrato_id", null: false
    t.integer "status"
    t.string "ano_mes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "nota", default: false
    t.boolean "boletim", default: false
    t.index ["contrato_id"], name: "index_transporte_escolar_servicos_on_contrato_id"
  end

  create_table "transporte_escolar_transportadores", force: :cascade do |t|
    t.integer "tipo"
    t.string "nome"
    t.string "cpf"
    t.string "razao_social"
    t.string "cnpj"
    t.bigint "municipio_id", null: false
    t.string "bairro"
    t.string "logradouro"
    t.string "numero"
    t.string "cep"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "codigo"
    t.string "banco"
    t.string "agencia"
    t.integer "tipo_de_conta"
    t.string "conta"
    t.boolean "doc_rg", default: false
    t.boolean "doc_cpf", default: false
    t.boolean "doc_carteira_maritima", default: false
    t.boolean "doc_dpen", default: false
    t.boolean "doc_tie", default: false
    t.boolean "doc_comprovante_endereco_contrato", default: false
    t.boolean "doc_certidao_negativa_estadual", default: false
    t.boolean "doc_certidao_negativa_federal", default: false
    t.boolean "doc_fotos_atualizadas", default: false
    t.boolean "doc_relacao_dos_alunos_por_rota", default: false
    t.boolean "doc_comprovante_conta_bancaria", default: false
    t.boolean "doc_cnh_categoria_d", default: false
    t.boolean "doc_auto_de_trafego", default: false
    t.boolean "doc_crlv", default: false
    t.boolean "doc_certificado_curso_de_condutor_escolar", default: false
    t.index ["municipio_id"], name: "index_transporte_escolar_transportadores_on_municipio_id"
  end

  create_table "transporte_escolar_veiculos", force: :cascade do |t|
    t.integer "tipo"
    t.string "identificacao"
    t.string "ano"
    t.string "modelo"
    t.string "marca"
    t.integer "capacidade_pessoas"
    t.integer "capacidade_carga"
    t.bigint "transportador_id", null: false
    t.bigint "condutor_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "procedencia"
    t.index ["condutor_id"], name: "index_transporte_escolar_veiculos_on_condutor_id"
    t.index ["transportador_id"], name: "index_transporte_escolar_veiculos_on_transportador_id"
  end

  create_table "unidades", force: :cascade do |t|
    t.string "nome"
    t.string "sigla"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "tipo_unidade_id", null: false
    t.index ["tipo_unidade_id"], name: "index_unidades_on_tipo_unidade_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "nome"
    t.string "celular"
    t.string "cpf"
    t.date "data_nascimento"
    t.bigint "unidade_id"
    t.bigint "funcao_id"
    t.boolean "status", default: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["funcao_id"], name: "index_users_on_funcao_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unidade_id"], name: "index_users_on_unidade_id"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "veiculos", force: :cascade do |t|
    t.string "placa"
    t.string "marca"
    t.string "modelo"
    t.integer "combustivel"
    t.integer "capacidade"
    t.integer "carga"
    t.integer "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "motorista_id"
    t.string "nome"
    t.float "consumo"
    t.index ["motorista_id"], name: "index_veiculos_on_motorista_id"
  end

  add_foreign_key "acoes", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "destinos", "requisicao_transportes"
  add_foreign_key "destinos", "users"
  add_foreign_key "etapa_users", "etapas"
  add_foreign_key "etapa_users", "users"
  add_foreign_key "etapas", "acoes"
  add_foreign_key "etapas_users", "etapas"
  add_foreign_key "etapas_users", "users"
  add_foreign_key "mensagens", "requisicao_tis"
  add_foreign_key "mensagens", "users"
  add_foreign_key "passageiros", "requisicao_transportes"
  add_foreign_key "passageiros", "users"
  add_foreign_key "problema_tis", "tipo_problema_tis"
  add_foreign_key "requisicao_tis", "cargos"
  add_foreign_key "requisicao_tis", "funcoes"
  add_foreign_key "requisicao_tis", "problema_tis"
  add_foreign_key "requisicao_tis", "unidades"
  add_foreign_key "requisicao_tis", "users"
  add_foreign_key "requisicao_tis", "users", column: "tecnico_id"
  add_foreign_key "requisicao_transportes", "unidades"
  add_foreign_key "requisicao_transportes", "users"
  add_foreign_key "servico_transportes", "motoristas"
  add_foreign_key "servico_transportes", "requisicao_transportes"
  add_foreign_key "servico_transportes", "veiculos"
  add_foreign_key "tarefas", "etapas"
  add_foreign_key "tarefas", "users"
  add_foreign_key "transporte_escolar_condutores", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_contratos", column: "veiculo_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_escolas", column: "escola_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_transportadores", column: "transportador_id"
  add_foreign_key "transporte_escolar_escolas", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_servicos", "transporte_escolar_contratos", column: "contrato_id"
  add_foreign_key "transporte_escolar_transportadores", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_veiculos", "transporte_escolar_condutores", column: "condutor_id"
  add_foreign_key "transporte_escolar_veiculos", "transporte_escolar_transportadores", column: "transportador_id"
  add_foreign_key "unidades", "tipo_unidades"
  add_foreign_key "users", "funcoes"
  add_foreign_key "users", "unidades"
  add_foreign_key "veiculos", "motoristas"
end
