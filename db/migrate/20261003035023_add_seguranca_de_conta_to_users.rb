# Segurança de conta (02-arquitetura-e-convencoes.md, seção 4). Só adições na
# tabela `users` herdada do siscom antigo.
class AddSegurancaDeContaToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      # Devise :lockable (bloqueio por tentativas, desbloqueio por tempo)
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :locked_at

      # Devise :trackable (registro de acesso)
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      # Troca obrigatória de senha e derrubada de sessões
      t.boolean :deve_trocar_senha, null: false, default: false
      t.integer :versao_sessao, null: false, default: 0
      t.datetime :senha_alterada_em
    end

    create_table :core_senhas_anteriores do |t|
      t.references :user, null: false, foreign_key: true
      t.string :senha_criptografada, null: false
      t.datetime :created_at, null: false
    end
  end
end
