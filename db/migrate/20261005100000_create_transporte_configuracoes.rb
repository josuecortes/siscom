# Configurações do Transporte (no seed ficam em system_settings, colunas transport_*): janelas de
# antecedência por tipo de solicitação, faixas de horas por modo de serviço e alertas. Uma linha só.
class CreateTransporteConfiguracoes < ActiveRecord::Migration[8.1]
  def change
    create_table :transporte_configuracoes do |t|
      t.integer :normal_antecedencia_min_horas, null: false, default: 48
      t.integer :normal_antecedencia_max_horas, null: false, default: 100
      t.integer :viagem_antecedencia_min_horas, null: false, default: 48
      t.integer :viagem_antecedencia_max_horas, null: false, default: 100
      t.integer :espera_min_horas, null: false, default: 1
      t.integer :espera_max_horas, null: false, default: 2
      t.integer :busca_min_horas, null: false, default: 1
      t.integer :busca_max_horas, null: false, default: 24
      t.integer :lembrete_saida_minutos, null: false, default: 30
      t.integer :aviso_busca_atrasada_minutos, null: false, default: 10
      t.timestamps
    end
  end
end
