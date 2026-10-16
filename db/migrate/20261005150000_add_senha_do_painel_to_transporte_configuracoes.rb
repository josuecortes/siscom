# Senha do painel de acompanhamento do Transporte (TV, sem login). No seed fica em texto puro em
# system_settings; aqui guarda-se só o resumo (BCrypt). Sem senha definida, o painel fica desligado.
class AddSenhaDoPainelToTransporteConfiguracoes < ActiveRecord::Migration[8.1]
  def change
    add_column :transporte_configuracoes, :senha_do_painel_digest, :string
  end
end
