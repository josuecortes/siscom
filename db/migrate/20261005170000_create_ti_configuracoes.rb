# Configuração da TI (uma linha só). Por enquanto guarda a senha do painel de acompanhamento para TV
# (só o resumo, como no Transporte); sem senha, o painel fica desligado.
class CreateTiConfiguracoes < ActiveRecord::Migration[8.1]
  def change
    create_table :ti_configuracoes do |t|
      t.string :senha_do_painel_digest
      t.timestamps
    end
  end
end
