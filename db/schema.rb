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

ActiveRecord::Schema.define(version: 2022_03_07_035920) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "departamentos", force: :cascade do |t|
    t.string "nome"
    t.string "sigla"
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

  create_table "funcoes", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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

  create_table "requisicao_transportes", force: :cascade do |t|
    t.integer "status"
    t.bigint "user_id", null: false
    t.bigint "departamento_id", null: false
    t.integer "tipo"
    t.string "documento_viagem"
    t.datetime "data_hora_ida"
    t.datetime "data_hora_retorno"
    t.text "motivo"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["departamento_id"], name: "index_requisicao_transportes_on_departamento_id"
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
    t.integer "km_inicial"
    t.integer "km_final"
    t.text "observacoes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["motorista_id"], name: "index_servico_transportes_on_motorista_id"
    t.index ["requisicao_transporte_id"], name: "index_servico_transportes_on_requisicao_transporte_id"
    t.index ["veiculo_id"], name: "index_servico_transportes_on_veiculo_id"
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
    t.bigint "departamento_id"
    t.bigint "funcao_id"
    t.index ["departamento_id"], name: "index_users_on_departamento_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["funcao_id"], name: "index_users_on_funcao_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
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
    t.index ["motorista_id"], name: "index_veiculos_on_motorista_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "destinos", "requisicao_transportes"
  add_foreign_key "destinos", "users"
  add_foreign_key "passageiros", "requisicao_transportes"
  add_foreign_key "passageiros", "users"
  add_foreign_key "requisicao_transportes", "departamentos"
  add_foreign_key "requisicao_transportes", "users"
  add_foreign_key "servico_transportes", "motoristas"
  add_foreign_key "servico_transportes", "requisicao_transportes"
  add_foreign_key "servico_transportes", "veiculos"
  add_foreign_key "users", "departamentos"
  add_foreign_key "users", "funcoes"
  add_foreign_key "veiculos", "motoristas"
end
