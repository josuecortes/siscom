# Módulo Equipamentos (porta de equipamentos / movimentacao_equipamentos / item_movimentacoes do siscom antigo,
# mais o empréstimo/cautela pedido pelo Josue em 2026-10-06). Só cria tabelas novas.
#
# - equipamentos_itens: o equipamento. `rh_unidade_id` é a unidade DONA; `situacao` diz se ele está livre, numa
#   movimentação ainda não recebida ou emprestado; `posse_rh_unidade_id` é a unidade que está com ele emprestado.
# - equipamentos_movimentacoes: um envio (movimentação definitiva, empréstimo ou cautela) de uma unidade para uma
#   pessoa de outra. No empréstimo guarda a previsão de devolução e o termo aceito por quem recebeu.
# - equipamentos_itens_movimentacao: cada equipamento do envio, com o recebimento e, no empréstimo, a devolução.
# - equipamentos_eventos: histórico de cada equipamento (cadastro, cada alteração com o antes e o depois,
#   movimentações, empréstimos), pesquisável.
class CreateEquipamentosItensEMovimentacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :equipamentos_itens do |t|
      t.string :tipo_equipamento, null: false
      t.text :descricao
      t.string :marca, null: false
      t.string :modelo, null: false
      t.string :numero_serial
      t.string :numero_patrimonio
      t.string :outra_identificacao
      t.string :status, null: false, default: "ativo"
      t.string :situacao, null: false, default: "disponivel"
      t.bigint :rh_unidade_id, null: false
      t.string :unidade_nome, null: false
      t.bigint :posse_rh_unidade_id
      t.string :posse_unidade_nome
      t.references :cadastrado_por, foreign_key: { to_table: :users }
      t.string :codigo_kit
      t.string :identificacao_kit
      t.string :contrato
      t.string :processo
      t.integer :garantia
      t.string :host
      t.string :ip
      t.string :mac
      t.string :ativo_de_rede
      t.string :localizacao_fisica
      t.string :rack
      t.bigint :legacy_id
      t.timestamps

      t.index :legacy_id, unique: true
      t.index :rh_unidade_id
      t.index :posse_rh_unidade_id
      t.index :codigo_kit
      t.index :status
      t.index :situacao
      t.index "upper(numero_serial)", unique: true, where: "numero_serial IS NOT NULL AND numero_serial <> ''", name: "idx_equipamentos_itens_serial"
      t.index "upper(numero_patrimonio)", unique: true, where: "numero_patrimonio IS NOT NULL AND numero_patrimonio <> ''", name: "idx_equipamentos_itens_patrimonio"
    end

    create_table :equipamentos_movimentacoes do |t|
      t.string :codigo
      t.string :tipo, null: false, default: "movimentacao"
      t.string :status, null: false, default: "em_andamento"
      t.bigint :origem_rh_unidade_id, null: false
      t.string :origem_nome, null: false
      t.bigint :destino_rh_unidade_id, null: false
      t.string :destino_nome, null: false
      t.references :responsavel, null: false, foreign_key: { to_table: :users }
      t.string :responsavel_nome, null: false
      t.references :criada_por, null: false, foreign_key: { to_table: :users }
      t.string :criada_por_nome, null: false
      t.text :descricao
      t.date :previsao_devolucao
      t.text :termo
      t.datetime :aceita_em
      t.datetime :encerrada_em
      t.bigint :legacy_id
      t.timestamps

      t.index :codigo, unique: true
      t.index :legacy_id, unique: true
      t.index :status
      t.index :tipo
      t.index :origem_rh_unidade_id
      t.index :destino_rh_unidade_id
    end

    create_table :equipamentos_itens_movimentacao do |t|
      t.references :movimentacao, null: false, foreign_key: { to_table: :equipamentos_movimentacoes }
      t.references :item, null: false, foreign_key: { to_table: :equipamentos_itens }
      t.string :status, null: false, default: "pendente"
      t.datetime :recebido_em
      t.references :recebido_por, foreign_key: { to_table: :users }
      t.datetime :cancelado_em
      t.references :cancelado_por, foreign_key: { to_table: :users }
      t.datetime :devolucao_pedida_em
      t.references :devolver_para, foreign_key: { to_table: :users }
      t.string :devolver_para_nome
      t.datetime :devolvido_em
      t.references :devolucao_recebida_por, foreign_key: { to_table: :users }
      t.text :observacao_da_devolucao
      t.bigint :legacy_id
      t.timestamps

      t.index :legacy_id, unique: true
      t.index :status
      # Um equipamento só pode estar em um envio aberto por vez.
      t.index :item_id, unique: true, where: "status IN ('pendente', 'emprestado', 'devolucao_pendente')", name: "idx_equipamentos_item_em_envio_aberto"
    end

    create_table :equipamentos_eventos do |t|
      t.references :item, null: false, foreign_key: { to_table: :equipamentos_itens }
      t.string :tipo, null: false
      t.text :nota
      t.jsonb :mudancas, null: false, default: {}
      t.references :ator, foreign_key: { to_table: :users }
      t.string :ator_nome
      t.datetime :ocorrido_em, null: false
      t.timestamps

      t.index :tipo
      t.index :ocorrido_em
    end
  end
end
