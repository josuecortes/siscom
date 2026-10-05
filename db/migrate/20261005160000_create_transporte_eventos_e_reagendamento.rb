# Histórico da solicitação de transporte (quem fez o quê e quando, visível ao solicitante) e
# reagendamento com aceite, como no siscom antigo: a operação muda a saída de uma solicitação
# aprovada, ela fica "reagendada" e o solicitante aceita (volta a aprovada) ou recusa (cancela).
class CreateTransporteEventosEReagendamento < ActiveRecord::Migration[8.1]
  def change
    create_table :transporte_eventos do |t|
      t.references :solicitacao, null: false, foreign_key: { to_table: :transporte_solicitacoes }
      t.string :tipo, null: false
      t.text :nota
      t.references :ator, foreign_key: { to_table: :users }
      t.string :ator_nome
      t.datetime :ocorrido_em, null: false
      t.timestamps
    end

    change_table :transporte_solicitacoes, bulk: true do |t|
      t.datetime :saida_anterior_em
      t.datetime :retorno_anterior_em
      t.text :motivo_reagendamento
      t.references :reagendada_por, foreign_key: { to_table: :users }
      t.datetime :reagendada_em
      t.text :motivo_recusa_reagendamento
      t.datetime :reagendamento_respondido_em
    end
  end
end
