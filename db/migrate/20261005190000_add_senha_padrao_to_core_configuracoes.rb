# Senha padrão das contas (pedido do Josue, 2026-10-05): a senha que a conta recebe quando é cadastrada e quando
# um administrador redefine a senha passa a ser definida em Administração → Configurações. Fica cifrada (o sistema
# precisa lê-la de volta para aplicar). Sem senha padrão definida, continua a senha temporária aleatória.
class AddSenhaPadraoToCoreConfiguracoes < ActiveRecord::Migration[8.1]
  def change
    add_column :core_configuracoes, :senha_padrao_cifrada, :text
  end
end
