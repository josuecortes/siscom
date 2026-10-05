# Solicitações de transporte (porta de transport_requests, transport_passengers e transport_destinations).
# Guarda o retrato do solicitante e da unidade na abertura. As colunas de aprovação, cancelamento e
# avisos já entram aqui; veículo e serviço do motorista vêm na fatia da operação.
class CreateTransporteSolicitacoes < ActiveRecord::Migration[8.1]
  def change
    create_table :transporte_solicitacoes do |t|
      t.string :codigo
      t.string :tipo, null: false, default: "normal"
      t.string :modo, null: false
      t.string :status, null: false, default: "solicitada"
      t.text :resumo, null: false
      t.datetime :saida_em, null: false
      t.datetime :retorno_em
      t.integer :espera_horas
      t.integer :busca_horas
      t.datetime :busca_prevista_em
      t.boolean :fora_do_padrao, null: false, default: false
      t.references :solicitante, null: false, foreign_key: { to_table: :users }
      t.string :solicitante_nome, null: false
      t.string :solicitante_email, null: false
      t.bigint :rh_unidade_id
      t.string :unidade_nome
      t.references :aberto_por, foreign_key: { to_table: :users }
      t.references :aprovada_por, foreign_key: { to_table: :users }
      t.datetime :aprovada_em
      t.references :cancelada_por, foreign_key: { to_table: :users }
      t.datetime :cancelada_em
      t.text :motivo_cancelamento
      t.datetime :lembrete_enviado_em
      t.datetime :ultimo_aviso_de_busca_em
      t.timestamps

      t.index :codigo, unique: true
      t.index :status
      t.index :saida_em
    end

    create_table :transporte_passageiros do |t|
      t.references :solicitacao, null: false, foreign_key: { to_table: :transporte_solicitacoes }
      t.string :cpf, null: false
      t.string :nome, null: false
      t.integer :posicao, null: false, default: 0
      t.timestamps
    end

    create_table :transporte_destinos do |t|
      t.references :solicitacao, null: false, foreign_key: { to_table: :transporte_solicitacoes }
      t.string :nome, null: false
      t.string :cep
      t.string :logradouro, null: false
      t.string :numero, null: false
      t.string :bairro, null: false
      t.string :cidade, null: false
      t.string :uf, null: false
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.integer :posicao, null: false, default: 0
      t.timestamps
    end
  end
end
