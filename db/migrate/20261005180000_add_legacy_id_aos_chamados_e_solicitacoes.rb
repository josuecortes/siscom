# Migração dos chamados de TI e das requisições de transporte do siscom antigo para os módulos novos
# (decisão do Josue, 2026-10-05: os dados antigos ficam junto com os novos, em vez de numa consulta à parte).
# `legacy_id` guarda o id da linha antiga (requisicao_tis.id / requisicao_transportes.id): é o que torna a
# importação idempotente (rodar de novo não duplica) e permite o de-para. Só adiciona colunas e índices.
class AddLegacyIdAosChamadosESolicitacoes < ActiveRecord::Migration[8.1]
  def change
    add_column :ti_chamados, :legacy_id, :bigint
    add_index :ti_chamados, :legacy_id, unique: true
    add_column :transporte_solicitacoes, :legacy_id, :bigint
    add_index :transporte_solicitacoes, :legacy_id, unique: true
  end
end
