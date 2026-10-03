# Usuário global do sistema (dono: Core). Tabela `users` herdada do siscom antigo:
# mesmos ids, e-mails e senhas bcrypt do Devise.
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  scope :ativos, -> { where(status: true) }

  def ativo?
    status != false
  end

  def active_for_authentication?
    super && ativo?
  end

  def inactive_message
    ativo? ? super : :inativo
  end
end
