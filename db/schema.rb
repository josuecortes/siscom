# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_05_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "acao_unidades", force: :cascade do |t|
    t.integer "nivel"
    t.bigint "acao_id", null: false
    t.bigint "unidade_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acao_id"], name: "index_acao_unidades_on_acao_id"
    t.index ["unidade_id"], name: "index_acao_unidades_on_unidade_id"
  end

  create_table "acao_users", force: :cascade do |t|
    t.integer "nivel"
    t.integer "status"
    t.date "inicio"
    t.date "fim"
    t.bigint "user_id", null: false
    t.bigint "acao_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acao_id"], name: "index_acao_users_on_acao_id"
    t.index ["user_id"], name: "index_acao_users_on_user_id"
  end

  create_table "acoes", force: :cascade do |t|
    t.string "nome"
    t.date "inicio"
    t.date "termino"
    t.string "motivacao"
    t.string "orcamento"
    t.integer "status"
    t.boolean "mostrar_no_site"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "documento_externo"
    t.string "local"
    t.string "documento"
    t.string "complexidade"
    t.index ["user_id"], name: "index_acoes_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cargos", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "core_acessos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "modulo", null: false
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "modulo"], name: "index_core_acessos_on_user_id_and_modulo", unique: true
    t.index ["user_id"], name: "index_core_acessos_on_user_id"
  end

  create_table "core_concessoes", force: :cascade do |t|
    t.bigint "acesso_id", null: false
    t.bigint "user_id", null: false
    t.string "modulo", null: false
    t.string "papel", null: false
    t.string "escopo_tipo"
    t.bigint "escopo_id"
    t.string "status", default: "ativo", null: false
    t.bigint "concedido_por_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acesso_id"], name: "index_core_concessoes_on_acesso_id"
    t.index ["concedido_por_id"], name: "index_core_concessoes_on_concedido_por_id"
    t.index ["escopo_tipo", "escopo_id"], name: "index_core_concessoes_on_escopo_tipo_and_escopo_id"
    t.index ["user_id", "modulo", "papel", "escopo_tipo", "escopo_id"], name: "idx_core_concessoes_ativa_escopo", unique: true, where: "(((status)::text = 'ativo'::text) AND (escopo_id IS NOT NULL))"
    t.index ["user_id", "modulo", "papel"], name: "idx_core_concessoes_ativa_global", unique: true, where: "(((status)::text = 'ativo'::text) AND (escopo_id IS NULL))"
    t.index ["user_id"], name: "index_core_concessoes_on_user_id"
  end

  create_table "core_configuracoes", force: :cascade do |t|
    t.string "nome_marca_web", default: "Siscom", null: false
    t.string "nome_marca_celular", default: "Siscom", null: false
    t.boolean "mostrar_nome_marca_web", default: true, null: false
    t.boolean "mostrar_nome_marca_celular", default: true, null: false
    t.boolean "mostrar_icone_marca_web", default: true, null: false
    t.boolean "mostrar_icone_marca_celular", default: true, null: false
    t.string "nome_cabecalho_web", default: "Siscom", null: false
    t.string "nome_cabecalho_celular", default: "Siscom", null: false
    t.boolean "mostrar_nome_cabecalho_web", default: true, null: false
    t.boolean "mostrar_nome_cabecalho_celular", default: true, null: false
    t.string "titulo_login", default: "Seed", null: false
    t.boolean "mostrar_titulo_login", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "core_conversas", force: :cascade do |t|
    t.string "modulo", null: false
    t.string "alvo_tipo", null: false
    t.bigint "alvo_id", null: false
    t.string "titulo", null: false
    t.string "url"
    t.string "status", default: "ativa", null: false
    t.string "motivo_leitura"
    t.datetime "ultima_mensagem_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alvo_tipo", "alvo_id"], name: "index_core_conversas_on_alvo_tipo_and_alvo_id", unique: true
  end

  create_table "core_fontes_referencia", force: :cascade do |t|
    t.string "chave", null: false
    t.string "nome", null: false
    t.text "descricao"
    t.string "modulo", null: false
    t.string "entidade", null: false
    t.string "campo_rotulo", null: false
    t.string "campo_valor", default: "id", null: false
    t.string "campo_subtitulo"
    t.string "campos_busca", default: [], null: false, array: true
    t.string "tipos_de_campo", default: [], null: false, array: true
    t.string "status", default: "ativo", null: false
    t.boolean "gerenciada_pelo_sistema", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chave"], name: "index_core_fontes_referencia_on_chave", unique: true
  end

  create_table "core_inscricoes_push", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "endpoint", null: false
    t.string "p256dh", null: false
    t.string "auth", null: false
    t.string "aparelho"
    t.datetime "ultimo_envio_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["endpoint"], name: "index_core_inscricoes_push_on_endpoint", unique: true
    t.index ["user_id"], name: "index_core_inscricoes_push_on_user_id"
  end

  create_table "core_mensagens", force: :cascade do |t|
    t.bigint "conversa_id", null: false
    t.bigint "autor_id"
    t.string "autor_nome"
    t.string "tipo", default: "texto", null: false
    t.text "corpo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["autor_id"], name: "index_core_mensagens_on_autor_id"
    t.index ["conversa_id"], name: "index_core_mensagens_on_conversa_id"
  end

  create_table "core_notificacoes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "ator_id"
    t.string "modulo", null: false
    t.string "evento", null: false
    t.string "titulo", null: false
    t.text "mensagem"
    t.string "url_acao"
    t.string "alvo_tipo"
    t.bigint "alvo_id"
    t.jsonb "dados", default: {}, null: false
    t.datetime "lida_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alvo_tipo", "alvo_id"], name: "index_core_notificacoes_on_alvo_tipo_and_alvo_id"
    t.index ["ator_id"], name: "index_core_notificacoes_on_ator_id"
    t.index ["user_id", "created_at"], name: "index_core_notificacoes_on_user_id_and_created_at"
    t.index ["user_id", "lida_em"], name: "index_core_notificacoes_on_user_id_and_lida_em"
    t.index ["user_id"], name: "index_core_notificacoes_on_user_id"
  end

  create_table "core_participantes", force: :cascade do |t|
    t.bigint "conversa_id", null: false
    t.bigint "user_id", null: false
    t.string "papel", default: "participante", null: false
    t.string "url"
    t.boolean "pode_ler", default: true, null: false
    t.boolean "pode_escrever", default: false, null: false
    t.bigint "lida_ate_id"
    t.datetime "entrou_em"
    t.datetime "saiu_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversa_id", "user_id"], name: "index_core_participantes_on_conversa_id_and_user_id", unique: true
    t.index ["conversa_id"], name: "index_core_participantes_on_conversa_id"
    t.index ["user_id"], name: "index_core_participantes_on_user_id"
  end

  create_table "core_registros_auditoria", force: :cascade do |t|
    t.string "modulo", null: false
    t.string "evento", null: false
    t.bigint "ator_id"
    t.string "ator_nome"
    t.string "alvo_tipo"
    t.bigint "alvo_id"
    t.string "alvo_descricao"
    t.jsonb "dados", default: {}, null: false
    t.string "ip"
    t.string "request_id"
    t.datetime "created_at", null: false
    t.index ["alvo_tipo", "alvo_id"], name: "index_core_registros_auditoria_on_alvo_tipo_and_alvo_id"
    t.index ["ator_id"], name: "index_core_registros_auditoria_on_ator_id"
    t.index ["created_at"], name: "index_core_registros_auditoria_on_created_at"
    t.index ["modulo", "evento"], name: "index_core_registros_auditoria_on_modulo_and_evento"
  end

  create_table "core_senhas_anteriores", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "senha_criptografada", null: false
    t.datetime "created_at", null: false
    t.index ["user_id"], name: "index_core_senhas_anteriores_on_user_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requisicao_transporte_id"], name: "index_destinos_on_requisicao_transporte_id"
    t.index ["user_id"], name: "index_destinos_on_user_id"
  end

  create_table "equipamentos", force: :cascade do |t|
    t.string "tipo", null: false
    t.text "descricao"
    t.string "marca"
    t.string "modelo"
    t.string "numero_serial"
    t.string "numero_patrimonio"
    t.string "outra_identificacao"
    t.integer "status", default: 0
    t.datetime "data_cadastro", precision: nil
    t.bigint "unidade_id", null: false
    t.bigint "user_id", null: false
    t.jsonb "itens_kit", default: []
    t.jsonb "historico_movimentacoes", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tipo_equipamento"
    t.string "identificacao_kit"
    t.string "host"
    t.string "ip"
    t.string "codigo_kit"
    t.string "contrato"
    t.integer "garantia"
    t.string "processo"
    t.string "localizacao_fisica"
    t.string "mac"
    t.string "rack"
    t.string "ativo_de_rede"
    t.index ["codigo_kit"], name: "index_equipamentos_on_codigo_kit"
    t.index ["contrato"], name: "index_equipamentos_on_contrato"
    t.index ["historico_movimentacoes"], name: "index_equipamentos_on_historico_movimentacoes", using: :gin
    t.index ["identificacao_kit"], name: "index_equipamentos_on_identificacao_kit"
    t.index ["itens_kit"], name: "index_equipamentos_on_itens_kit", using: :gin
    t.index ["mac"], name: "index_equipamentos_on_mac", unique: true
    t.index ["numero_patrimonio"], name: "index_equipamentos_on_numero_patrimonio"
    t.index ["numero_serial"], name: "index_equipamentos_on_numero_serial"
    t.index ["status"], name: "index_equipamentos_on_status"
    t.index ["tipo"], name: "index_equipamentos_on_tipo"
    t.index ["tipo_equipamento"], name: "index_equipamentos_on_tipo_equipamento"
    t.index ["unidade_id"], name: "index_equipamentos_on_unidade_id"
    t.index ["user_id"], name: "index_equipamentos_on_user_id"
  end

  create_table "etapa_users", force: :cascade do |t|
    t.bigint "etapa_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["acao_id"], name: "index_etapas_on_acao_id"
  end

  create_table "funcoes", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "incidentes", force: :cascade do |t|
    t.string "descricao"
    t.string "texto_explicativo"
    t.string "previsao_de_retorno"
    t.datetime "data_hora_inicio", precision: nil
    t.datetime "data_hora_fim", precision: nil
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "item_movimentacoes", force: :cascade do |t|
    t.bigint "movimentacao_equipamento_id", null: false
    t.bigint "equipamento_id", null: false
    t.boolean "recebido", default: false
    t.datetime "data_recebimento", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "pendente"
    t.index ["equipamento_id"], name: "index_item_movimentacoes_on_equipamento_id"
    t.index ["movimentacao_equipamento_id"], name: "index_item_movimentacoes_on_movimentacao_equipamento_id"
  end

  create_table "mensagens", force: :cascade do |t|
    t.string "status"
    t.text "texto"
    t.bigint "user_id", null: false
    t.bigint "requisicao_ti_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
  end

  create_table "movimentacao_equipamentos", force: :cascade do |t|
    t.bigint "unidade_origem_id", null: false
    t.bigint "unidade_destino_id", null: false
    t.bigint "responsavel_id", null: false
    t.string "status", default: "em_andamento"
    t.text "descricao"
    t.datetime "data_movimentacao", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["responsavel_id"], name: "index_movimentacao_equipamentos_on_responsavel_id"
    t.index ["unidade_destino_id"], name: "index_movimentacao_equipamentos_on_unidade_destino_id"
    t.index ["unidade_origem_id"], name: "index_movimentacao_equipamentos_on_unidade_origem_id"
    t.index ["user_id"], name: "index_movimentacao_equipamentos_on_user_id"
  end

  create_table "passageiros", force: :cascade do |t|
    t.string "nome"
    t.string "celular"
    t.string "cpf"
    t.bigint "requisicao_transporte_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requisicao_transporte_id"], name: "index_passageiros_on_requisicao_transporte_id"
    t.index ["user_id"], name: "index_passageiros_on_user_id"
  end

  create_table "problema_tis", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.bigint "tipo_problema_ti_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "data_hora_em_atendimento", precision: nil
    t.datetime "data_hora_concluida", precision: nil
    t.datetime "data_hora_finalizada", precision: nil
    t.text "unidade_destino"
    t.string "nae"
    t.text "permissao_drive"
    t.text "nome_arquivo"
    t.string "prodoc_nome_da_instituicao_externa", limit: 140
    t.string "prodoc_sigla_da_instituicao_externa", limit: 30
    t.string "prodoc_nome_unidade_organizacional_externa", limit: 140
    t.string "prodoc_sigla_unidade_organizacional_externa", limit: 30
    t.string "prodoc_responsavel_instituicao_externa", limit: 140
    t.string "prodoc_cargo_do_responsavel_instituicao_externa", limit: 140
    t.string "prodoc_pronome_responsavel_instituicao_externa", limit: 100
    t.string "prodoc_cep_instituicao_externa"
    t.string "prodoc_cidade_instituicao_externa"
    t.string "prodoc_uf_instituicao_externa"
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
    t.datetime "data_hora_ida", precision: nil
    t.datetime "data_hora_retorno", precision: nil
    t.text "motivo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "data_hora_aprovada", precision: nil
    t.datetime "data_hora_em_servico", precision: nil
    t.datetime "data_hora_negada", precision: nil
    t.datetime "data_hora_finalizada", precision: nil
    t.text "motivo_negada"
    t.string "usuario_aprovou"
    t.string "usuario_negou"
    t.string "usuario_em_servico"
    t.string "usuario_finalizou"
    t.bigint "usuario_reagendou_id"
    t.datetime "data_hora_reagendou", precision: nil
    t.datetime "data_hora_ida_antiga", precision: nil
    t.datetime "data_hora_retorno_antiga", precision: nil
    t.bigint "usuario_aceitou_negou_reagendamento_id"
    t.datetime "data_hora_aceitou_negou_reagendamento", precision: nil
    t.text "motivo_reagendamento"
    t.text "motivo_negacao_reagendamento"
    t.boolean "requisicao_reagendada", default: false
    t.index ["unidade_id"], name: "index_requisicao_transportes_on_unidade_id"
    t.index ["user_id"], name: "index_requisicao_transportes_on_user_id"
    t.index ["usuario_aceitou_negou_reagendamento_id"], name: "idx_rt_usr_anr_id"
    t.index ["usuario_reagendou_id"], name: "index_requisicao_transportes_on_usuario_reagendou_id"
  end

  create_table "rh_cargos", force: :cascade do |t|
    t.string "nome", null: false
    t.string "status", default: "ativo", null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_rh_cargos_nome", unique: true
    t.index ["legacy_id"], name: "index_rh_cargos_on_legacy_id", unique: true
  end

  create_table "rh_dados_escola", force: :cascade do |t|
    t.bigint "unidade_id", null: false
    t.string "nae"
    t.string "codigo_inep"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "cep"
    t.string "logradouro"
    t.string "numero"
    t.string "complemento"
    t.string "bairro"
    t.string "cidade"
    t.string "uf", limit: 2
    t.index ["unidade_id"], name: "index_rh_dados_escola_on_unidade_id", unique: true
  end

  create_table "rh_funcoes", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_rh_funcoes_nome", unique: true
    t.index ["legacy_id"], name: "index_rh_funcoes_on_legacy_id", unique: true
  end

  create_table "rh_lotacoes", force: :cascade do |t|
    t.bigint "pessoa_id", null: false
    t.bigint "unidade_id", null: false
    t.bigint "funcao_id", null: false
    t.date "data_inicio", null: false
    t.date "data_fim"
    t.string "status", default: "ativo", null: false
    t.datetime "lotado_em", null: false
    t.string "lotado_por_nome"
    t.string "lotado_por_email"
    t.datetime "encerrado_em"
    t.string "encerrado_por_nome"
    t.string "encerrado_por_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["funcao_id"], name: "index_rh_lotacoes_on_funcao_id"
    t.index ["pessoa_id", "unidade_id", "funcao_id"], name: "idx_rh_lotacoes_ativa", unique: true, where: "((status)::text = 'ativo'::text)"
    t.index ["pessoa_id"], name: "index_rh_lotacoes_on_pessoa_id"
    t.index ["unidade_id"], name: "index_rh_lotacoes_on_unidade_id"
  end

  create_table "rh_pendencias_importacao", force: :cascade do |t|
    t.bigint "pessoa_id"
    t.string "tipo", null: false
    t.string "descricao", null: false
    t.datetime "resolvida_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pessoa_id", "tipo"], name: "index_rh_pendencias_importacao_on_pessoa_id_and_tipo", unique: true
    t.index ["pessoa_id"], name: "index_rh_pendencias_importacao_on_pessoa_id"
    t.index ["tipo"], name: "index_rh_pendencias_importacao_on_tipo"
  end

  create_table "rh_pessoas", force: :cascade do |t|
    t.bigint "user_id"
    t.string "nome", null: false
    t.string "email", null: false
    t.string "celular"
    t.string "cpf"
    t.date "data_nascimento"
    t.string "sexo", default: "nao_informado", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "idx_rh_pessoas_email", unique: true
    t.index ["cpf"], name: "index_rh_pessoas_on_cpf", unique: true, where: "(cpf IS NOT NULL)"
    t.index ["user_id"], name: "index_rh_pessoas_on_user_id", unique: true
  end

  create_table "rh_tipos_local", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_rh_tipos_local_nome", unique: true
  end

  create_table "rh_tipos_unidade", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_rh_tipos_unidade_nome", unique: true
    t.index ["legacy_id"], name: "index_rh_tipos_unidade_on_legacy_id", unique: true
  end

  create_table "rh_tipos_vinculo", force: :cascade do |t|
    t.string "nome", null: false
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_rh_tipos_vinculo_nome", unique: true
  end

  create_table "rh_unidades", force: :cascade do |t|
    t.string "nome", null: false
    t.string "sigla"
    t.bigint "tipo_unidade_id", null: false
    t.bigint "tipo_local_id"
    t.bigint "pai_id"
    t.string "status", default: "ativo", null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((sigla)::text)", name: "idx_rh_unidades_sigla", unique: true, where: "(sigla IS NOT NULL)"
    t.index ["legacy_id"], name: "index_rh_unidades_on_legacy_id", unique: true
    t.index ["pai_id"], name: "index_rh_unidades_on_pai_id"
    t.index ["tipo_local_id"], name: "index_rh_unidades_on_tipo_local_id"
    t.index ["tipo_unidade_id"], name: "index_rh_unidades_on_tipo_unidade_id"
  end

  create_table "rh_vinculos", force: :cascade do |t|
    t.bigint "pessoa_id", null: false
    t.bigint "tipo_vinculo_id", null: false
    t.bigint "cargo_id", null: false
    t.date "data_inicio", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cargo_id"], name: "index_rh_vinculos_on_cargo_id"
    t.index ["pessoa_id"], name: "index_rh_vinculos_on_pessoa_id", unique: true
    t.index ["tipo_vinculo_id"], name: "index_rh_vinculos_on_tipo_vinculo_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["motorista_id"], name: "index_servico_transportes_on_motorista_id"
    t.index ["requisicao_transporte_id"], name: "index_servico_transportes_on_requisicao_transporte_id"
    t.index ["veiculo_id"], name: "index_servico_transportes_on_veiculo_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.binary "payload", null: false
    t.datetime "created_at", null: false
    t.bigint "channel_hash", null: false
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", null: false
    t.binary "value", null: false
    t.datetime "created_at", null: false
    t.bigint "key_hash", null: false
    t.integer "byte_size", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tarefa_comentarios", force: :cascade do |t|
    t.bigint "tarefa_id", null: false
    t.bigint "user_id", null: false
    t.string "texto", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tarefa_comentarios_on_created_at"
    t.index ["tarefa_id"], name: "index_tarefa_comentarios_on_tarefa_id"
    t.index ["user_id"], name: "index_tarefa_comentarios_on_user_id"
  end

  create_table "tarefas", force: :cascade do |t|
    t.string "titulo"
    t.string "descricao"
    t.datetime "inicio", precision: nil
    t.datetime "fim", precision: nil
    t.integer "tipo"
    t.integer "status"
    t.bigint "etapa_id"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prioridade"
    t.date "prazo"
    t.bigint "created_by_id"
    t.index ["created_by_id"], name: "index_tarefas_on_created_by_id"
    t.index ["etapa_id"], name: "index_tarefas_on_etapa_id"
    t.index ["user_id"], name: "index_tarefas_on_user_id"
  end

  create_table "ti_campos_problema", force: :cascade do |t|
    t.bigint "problema_id", null: false
    t.string "chave", null: false
    t.string "rotulo", null: false
    t.string "tipo", default: "texto", null: false
    t.boolean "obrigatorio", default: false, null: false
    t.integer "posicao", default: 0, null: false
    t.string "exemplo"
    t.string "mascara"
    t.text "ajuda"
    t.jsonb "config", default: {}, null: false
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["problema_id", "chave"], name: "index_ti_campos_problema_on_problema_id_and_chave", unique: true
    t.index ["problema_id"], name: "index_ti_campos_problema_on_problema_id"
  end

  create_table "ti_categorias", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_ti_categorias_nome", unique: true
    t.index ["legacy_id"], name: "index_ti_categorias_on_legacy_id", unique: true
  end

  create_table "ti_chamados", force: :cascade do |t|
    t.string "codigo"
    t.bigint "problema_id", null: false
    t.string "status", default: "aberto", null: false
    t.string "prioridade", default: "normal", null: false
    t.bigint "solicitante_id", null: false
    t.string "solicitante_nome", null: false
    t.string "solicitante_email", null: false
    t.bigint "rh_unidade_id"
    t.string "unidade_nome"
    t.string "funcao_nome"
    t.bigint "triador_id"
    t.bigint "responsavel_id"
    t.text "nota_triagem"
    t.datetime "triado_em"
    t.datetime "aberto_em", null: false
    t.datetime "concluido_em"
    t.datetime "finalizado_em"
    t.integer "avaliacao"
    t.boolean "avaliacao_resolvido"
    t.text "avaliacao_comentario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "aberto_por_id"
    t.index ["aberto_por_id"], name: "index_ti_chamados_on_aberto_por_id"
    t.index ["codigo"], name: "index_ti_chamados_on_codigo", unique: true
    t.index ["problema_id"], name: "index_ti_chamados_on_problema_id"
    t.index ["responsavel_id"], name: "index_ti_chamados_on_responsavel_id"
    t.index ["rh_unidade_id"], name: "index_ti_chamados_on_rh_unidade_id"
    t.index ["solicitante_id"], name: "index_ti_chamados_on_solicitante_id"
    t.index ["status"], name: "index_ti_chamados_on_status"
    t.index ["triador_id"], name: "index_ti_chamados_on_triador_id"
  end

  create_table "ti_eventos_chamado", force: :cascade do |t|
    t.bigint "chamado_id", null: false
    t.string "tipo", null: false
    t.string "de_status"
    t.string "para_status"
    t.text "nota"
    t.bigint "ator_id"
    t.string "ator_nome"
    t.datetime "ocorrido_em", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ator_id"], name: "index_ti_eventos_chamado_on_ator_id"
    t.index ["chamado_id"], name: "index_ti_eventos_chamado_on_chamado_id"
  end

  create_table "ti_grupos_tecnicos", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.boolean "permite_autoatribuicao", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_ti_grupos_tecnicos_nome", unique: true
  end

  create_table "ti_membros_grupo", force: :cascade do |t|
    t.bigint "grupo_tecnico_id", null: false
    t.bigint "user_id", null: false
    t.bigint "concedido_por_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concedido_por_id"], name: "index_ti_membros_grupo_on_concedido_por_id"
    t.index ["grupo_tecnico_id", "user_id"], name: "index_ti_membros_grupo_on_grupo_tecnico_id_and_user_id", unique: true
    t.index ["grupo_tecnico_id"], name: "index_ti_membros_grupo_on_grupo_tecnico_id"
    t.index ["user_id"], name: "index_ti_membros_grupo_on_user_id"
  end

  create_table "ti_perfis_abertura", force: :cascade do |t|
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "padrao", default: false, null: false
    t.index "lower((nome)::text)", name: "idx_ti_perfis_abertura_nome", unique: true
  end

  create_table "ti_perfis_usuario", force: :cascade do |t|
    t.bigint "perfil_abertura_id", null: false
    t.bigint "user_id", null: false
    t.bigint "concedido_por_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["concedido_por_id"], name: "index_ti_perfis_usuario_on_concedido_por_id"
    t.index ["perfil_abertura_id", "user_id"], name: "index_ti_perfis_usuario_on_perfil_abertura_id_and_user_id", unique: true
    t.index ["perfil_abertura_id"], name: "index_ti_perfis_usuario_on_perfil_abertura_id"
    t.index ["user_id"], name: "index_ti_perfis_usuario_on_user_id"
  end

  create_table "ti_problemas", force: :cascade do |t|
    t.bigint "categoria_id", null: false
    t.string "nome", null: false
    t.text "descricao"
    t.string "status", default: "ativo", null: false
    t.string "prioridade_padrao", default: "normal", null: false
    t.boolean "exige_triagem", default: true, null: false
    t.boolean "permite_varios_abertos", default: false, null: false
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "categoria_id, lower((nome)::text)", name: "idx_ti_problemas_categoria_nome", unique: true
    t.index ["categoria_id"], name: "index_ti_problemas_on_categoria_id"
    t.index ["legacy_id"], name: "index_ti_problemas_on_legacy_id", unique: true
  end

  create_table "ti_problemas_grupos", force: :cascade do |t|
    t.bigint "problema_id", null: false
    t.bigint "grupo_tecnico_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grupo_tecnico_id"], name: "index_ti_problemas_grupos_on_grupo_tecnico_id"
    t.index ["problema_id", "grupo_tecnico_id"], name: "index_ti_problemas_grupos_on_problema_id_and_grupo_tecnico_id", unique: true
    t.index ["problema_id"], name: "index_ti_problemas_grupos_on_problema_id"
  end

  create_table "ti_problemas_perfis", force: :cascade do |t|
    t.bigint "problema_id", null: false
    t.bigint "perfil_abertura_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["perfil_abertura_id"], name: "index_ti_problemas_perfis_on_perfil_abertura_id"
    t.index ["problema_id", "perfil_abertura_id"], name: "idx_on_problema_id_perfil_abertura_id_c47da1bd87", unique: true
    t.index ["problema_id"], name: "index_ti_problemas_perfis_on_problema_id"
  end

  create_table "ti_valores_campo", force: :cascade do |t|
    t.bigint "chamado_id", null: false
    t.bigint "campo_problema_id", null: false
    t.string "rotulo", null: false
    t.string "tipo", null: false
    t.text "valor_texto"
    t.jsonb "valor_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campo_problema_id"], name: "index_ti_valores_campo_on_campo_problema_id"
    t.index ["chamado_id", "campo_problema_id"], name: "index_ti_valores_campo_on_chamado_id_and_campo_problema_id", unique: true
    t.index ["chamado_id"], name: "index_ti_valores_campo_on_chamado_id"
  end

  create_table "tipo_problema_tis", force: :cascade do |t|
    t.string "nome"
    t.text "descricao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tipo_unidades", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transporte_configuracoes", force: :cascade do |t|
    t.integer "normal_antecedencia_min_horas", default: 48, null: false
    t.integer "normal_antecedencia_max_horas", default: 100, null: false
    t.integer "viagem_antecedencia_min_horas", default: 48, null: false
    t.integer "viagem_antecedencia_max_horas", default: 100, null: false
    t.integer "espera_min_horas", default: 1, null: false
    t.integer "espera_max_horas", default: 2, null: false
    t.integer "busca_min_horas", default: 1, null: false
    t.integer "busca_max_horas", default: 24, null: false
    t.integer "lembrete_saida_minutos", default: 30, null: false
    t.integer "aviso_busca_atrasada_minutos", default: 10, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "senha_do_painel_digest"
  end

  create_table "transporte_destinos", force: :cascade do |t|
    t.bigint "solicitacao_id", null: false
    t.string "nome", null: false
    t.string "cep"
    t.string "logradouro", null: false
    t.string "numero", null: false
    t.string "bairro", null: false
    t.string "cidade", null: false
    t.string "uf", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "posicao", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["solicitacao_id"], name: "index_transporte_destinos_on_solicitacao_id"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipio_id"], name: "index_transporte_escolar_escolas_on_municipio_id"
  end

  create_table "transporte_escolar_municipios", force: :cascade do |t|
    t.string "nome"
    t.integer "tipo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transporte_escolar_servicos", force: :cascade do |t|
    t.string "numero"
    t.integer "diarias"
    t.bigint "contrato_id", null: false
    t.integer "status"
    t.string "ano_mes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "procedencia"
    t.index ["condutor_id"], name: "index_transporte_escolar_veiculos_on_condutor_id"
    t.index ["transportador_id"], name: "index_transporte_escolar_veiculos_on_transportador_id"
  end

  create_table "transporte_motoristas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nome", null: false
    t.string "cpf", null: false
    t.date "data_nascimento", null: false
    t.string "cnh_numero", null: false
    t.string "cnh_categoria", null: false
    t.date "cnh_validade", null: false
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cnh_numero"], name: "index_transporte_motoristas_on_cnh_numero", unique: true
    t.index ["cpf"], name: "index_transporte_motoristas_on_cpf", unique: true
    t.index ["user_id"], name: "index_transporte_motoristas_on_user_id", unique: true
  end

  create_table "transporte_observacoes", force: :cascade do |t|
    t.bigint "solicitacao_id", null: false
    t.bigint "autor_id", null: false
    t.string "autor_nome", null: false
    t.string "papel", null: false
    t.text "corpo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["autor_id"], name: "index_transporte_observacoes_on_autor_id"
    t.index ["solicitacao_id"], name: "index_transporte_observacoes_on_solicitacao_id"
  end

  create_table "transporte_passageiros", force: :cascade do |t|
    t.bigint "solicitacao_id", null: false
    t.string "cpf", null: false
    t.string "nome", null: false
    t.integer "posicao", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["solicitacao_id"], name: "index_transporte_passageiros_on_solicitacao_id"
  end

  create_table "transporte_servicos", force: :cascade do |t|
    t.bigint "solicitacao_id", null: false
    t.string "trecho", default: "ida", null: false
    t.bigint "motorista_id", null: false
    t.string "motorista_nome", null: false
    t.bigint "veiculo_id", null: false
    t.string "placa", null: false
    t.bigint "odometro_inicial", null: false
    t.bigint "odometro_final"
    t.datetime "iniciado_em", null: false
    t.datetime "finalizado_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "grupo"
    t.index ["grupo"], name: "index_transporte_servicos_on_grupo"
    t.index ["motorista_id"], name: "index_transporte_servicos_on_motorista_id"
    t.index ["solicitacao_id"], name: "idx_transporte_servicos_solicitacao_em_uso", unique: true, where: "(finalizado_em IS NULL)"
    t.index ["solicitacao_id"], name: "index_transporte_servicos_on_solicitacao_id"
    t.index ["veiculo_id"], name: "idx_transporte_servicos_veiculo_aberto", where: "(finalizado_em IS NULL)"
    t.index ["veiculo_id"], name: "index_transporte_servicos_on_veiculo_id"
  end

  create_table "transporte_solicitacoes", force: :cascade do |t|
    t.string "codigo"
    t.string "tipo", default: "normal", null: false
    t.string "modo", null: false
    t.string "status", default: "solicitada", null: false
    t.text "resumo", null: false
    t.datetime "saida_em", null: false
    t.datetime "retorno_em"
    t.integer "espera_horas"
    t.integer "busca_horas"
    t.datetime "busca_prevista_em"
    t.boolean "fora_do_padrao", default: false, null: false
    t.bigint "solicitante_id", null: false
    t.string "solicitante_nome", null: false
    t.string "solicitante_email", null: false
    t.bigint "rh_unidade_id"
    t.string "unidade_nome"
    t.bigint "aberto_por_id"
    t.bigint "aprovada_por_id"
    t.datetime "aprovada_em"
    t.bigint "cancelada_por_id"
    t.datetime "cancelada_em"
    t.text "motivo_cancelamento"
    t.datetime "lembrete_enviado_em"
    t.datetime "ultimo_aviso_de_busca_em"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "concluida_em"
    t.index ["aberto_por_id"], name: "index_transporte_solicitacoes_on_aberto_por_id"
    t.index ["aprovada_por_id"], name: "index_transporte_solicitacoes_on_aprovada_por_id"
    t.index ["cancelada_por_id"], name: "index_transporte_solicitacoes_on_cancelada_por_id"
    t.index ["codigo"], name: "index_transporte_solicitacoes_on_codigo", unique: true
    t.index ["saida_em"], name: "index_transporte_solicitacoes_on_saida_em"
    t.index ["solicitante_id"], name: "index_transporte_solicitacoes_on_solicitante_id"
    t.index ["status"], name: "index_transporte_solicitacoes_on_status"
  end

  create_table "transporte_veiculos", force: :cascade do |t|
    t.string "placa", null: false
    t.string "marca", null: false
    t.string "modelo", null: false
    t.integer "ano", null: false
    t.string "cor", null: false
    t.integer "capacidade", null: false
    t.string "combustivel", null: false
    t.decimal "consumo_km_por_litro", precision: 10, scale: 2, null: false
    t.bigint "odometro_atual", default: 0, null: false
    t.string "status", default: "ativo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placa"], name: "index_transporte_veiculos_on_placa", unique: true
  end

  create_table "unidades", force: :cascade do |t|
    t.string "nome"
    t.string "sigla"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tipo_unidade_id", null: false
    t.index ["tipo_unidade_id"], name: "index_unidades_on_tipo_unidade_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nome"
    t.string "celular"
    t.string "cpf"
    t.date "data_nascimento"
    t.bigint "unidade_id"
    t.bigint "funcao_id"
    t.boolean "status", default: true
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.boolean "deve_trocar_senha", default: false, null: false
    t.integer "versao_sessao", default: 0, null: false
    t.datetime "senha_alterada_em"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "motorista_id"
    t.string "nome"
    t.float "consumo"
    t.index ["motorista_id"], name: "index_veiculos_on_motorista_id"
  end

  add_foreign_key "acao_unidades", "acoes"
  add_foreign_key "acao_unidades", "unidades"
  add_foreign_key "acao_users", "acoes"
  add_foreign_key "acao_users", "users"
  add_foreign_key "acoes", "users"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "core_acessos", "users"
  add_foreign_key "core_concessoes", "core_acessos", column: "acesso_id"
  add_foreign_key "core_concessoes", "users"
  add_foreign_key "core_concessoes", "users", column: "concedido_por_id"
  add_foreign_key "core_inscricoes_push", "users"
  add_foreign_key "core_mensagens", "core_conversas", column: "conversa_id"
  add_foreign_key "core_mensagens", "users", column: "autor_id"
  add_foreign_key "core_notificacoes", "users"
  add_foreign_key "core_notificacoes", "users", column: "ator_id"
  add_foreign_key "core_participantes", "core_conversas", column: "conversa_id"
  add_foreign_key "core_participantes", "users"
  add_foreign_key "core_registros_auditoria", "users", column: "ator_id"
  add_foreign_key "core_senhas_anteriores", "users"
  add_foreign_key "destinos", "requisicao_transportes"
  add_foreign_key "destinos", "users"
  add_foreign_key "equipamentos", "unidades"
  add_foreign_key "equipamentos", "users"
  add_foreign_key "etapa_users", "etapas"
  add_foreign_key "etapa_users", "users"
  add_foreign_key "etapas", "acoes"
  add_foreign_key "item_movimentacoes", "equipamentos"
  add_foreign_key "item_movimentacoes", "movimentacao_equipamentos"
  add_foreign_key "mensagens", "requisicao_tis"
  add_foreign_key "mensagens", "users"
  add_foreign_key "movimentacao_equipamentos", "unidades", column: "unidade_destino_id"
  add_foreign_key "movimentacao_equipamentos", "unidades", column: "unidade_origem_id"
  add_foreign_key "movimentacao_equipamentos", "users"
  add_foreign_key "movimentacao_equipamentos", "users", column: "responsavel_id"
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
  add_foreign_key "requisicao_transportes", "users", column: "usuario_aceitou_negou_reagendamento_id"
  add_foreign_key "requisicao_transportes", "users", column: "usuario_reagendou_id"
  add_foreign_key "rh_dados_escola", "rh_unidades", column: "unidade_id"
  add_foreign_key "rh_lotacoes", "rh_funcoes", column: "funcao_id"
  add_foreign_key "rh_lotacoes", "rh_pessoas", column: "pessoa_id"
  add_foreign_key "rh_lotacoes", "rh_unidades", column: "unidade_id"
  add_foreign_key "rh_pendencias_importacao", "rh_pessoas", column: "pessoa_id"
  add_foreign_key "rh_pessoas", "users"
  add_foreign_key "rh_unidades", "rh_tipos_local", column: "tipo_local_id"
  add_foreign_key "rh_unidades", "rh_tipos_unidade", column: "tipo_unidade_id"
  add_foreign_key "rh_unidades", "rh_unidades", column: "pai_id"
  add_foreign_key "rh_vinculos", "rh_cargos", column: "cargo_id"
  add_foreign_key "rh_vinculos", "rh_pessoas", column: "pessoa_id"
  add_foreign_key "rh_vinculos", "rh_tipos_vinculo", column: "tipo_vinculo_id"
  add_foreign_key "servico_transportes", "motoristas"
  add_foreign_key "servico_transportes", "requisicao_transportes"
  add_foreign_key "servico_transportes", "veiculos"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "tarefa_comentarios", "tarefas"
  add_foreign_key "tarefa_comentarios", "users"
  add_foreign_key "tarefas", "etapas"
  add_foreign_key "tarefas", "users"
  add_foreign_key "tarefas", "users", column: "created_by_id"
  add_foreign_key "ti_campos_problema", "ti_problemas", column: "problema_id"
  add_foreign_key "ti_chamados", "ti_problemas", column: "problema_id"
  add_foreign_key "ti_chamados", "users", column: "aberto_por_id"
  add_foreign_key "ti_chamados", "users", column: "responsavel_id"
  add_foreign_key "ti_chamados", "users", column: "solicitante_id"
  add_foreign_key "ti_chamados", "users", column: "triador_id"
  add_foreign_key "ti_eventos_chamado", "ti_chamados", column: "chamado_id"
  add_foreign_key "ti_eventos_chamado", "users", column: "ator_id"
  add_foreign_key "ti_membros_grupo", "ti_grupos_tecnicos", column: "grupo_tecnico_id"
  add_foreign_key "ti_membros_grupo", "users"
  add_foreign_key "ti_membros_grupo", "users", column: "concedido_por_id"
  add_foreign_key "ti_perfis_usuario", "ti_perfis_abertura", column: "perfil_abertura_id"
  add_foreign_key "ti_perfis_usuario", "users"
  add_foreign_key "ti_perfis_usuario", "users", column: "concedido_por_id"
  add_foreign_key "ti_problemas", "ti_categorias", column: "categoria_id"
  add_foreign_key "ti_problemas_grupos", "ti_grupos_tecnicos", column: "grupo_tecnico_id"
  add_foreign_key "ti_problemas_grupos", "ti_problemas", column: "problema_id"
  add_foreign_key "ti_problemas_perfis", "ti_perfis_abertura", column: "perfil_abertura_id"
  add_foreign_key "ti_problemas_perfis", "ti_problemas", column: "problema_id"
  add_foreign_key "ti_valores_campo", "ti_campos_problema", column: "campo_problema_id"
  add_foreign_key "ti_valores_campo", "ti_chamados", column: "chamado_id"
  add_foreign_key "transporte_destinos", "transporte_solicitacoes", column: "solicitacao_id"
  add_foreign_key "transporte_escolar_condutores", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_contratos", column: "veiculo_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_escolas", column: "escola_id"
  add_foreign_key "transporte_escolar_contratos", "transporte_escolar_transportadores", column: "transportador_id"
  add_foreign_key "transporte_escolar_escolas", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_servicos", "transporte_escolar_contratos", column: "contrato_id"
  add_foreign_key "transporte_escolar_transportadores", "transporte_escolar_municipios", column: "municipio_id"
  add_foreign_key "transporte_escolar_veiculos", "transporte_escolar_condutores", column: "condutor_id"
  add_foreign_key "transporte_escolar_veiculos", "transporte_escolar_transportadores", column: "transportador_id"
  add_foreign_key "transporte_motoristas", "users"
  add_foreign_key "transporte_observacoes", "transporte_solicitacoes", column: "solicitacao_id"
  add_foreign_key "transporte_observacoes", "users", column: "autor_id"
  add_foreign_key "transporte_passageiros", "transporte_solicitacoes", column: "solicitacao_id"
  add_foreign_key "transporte_servicos", "transporte_solicitacoes", column: "solicitacao_id"
  add_foreign_key "transporte_servicos", "transporte_veiculos", column: "veiculo_id"
  add_foreign_key "transporte_servicos", "users", column: "motorista_id"
  add_foreign_key "transporte_solicitacoes", "users", column: "aberto_por_id"
  add_foreign_key "transporte_solicitacoes", "users", column: "aprovada_por_id"
  add_foreign_key "transporte_solicitacoes", "users", column: "cancelada_por_id"
  add_foreign_key "transporte_solicitacoes", "users", column: "solicitante_id"
  add_foreign_key "unidades", "tipo_unidades"
  add_foreign_key "users", "funcoes"
  add_foreign_key "users", "unidades"
  add_foreign_key "veiculos", "motoristas"
end
