# Usuário global do sistema (dono: Core). Tabela `users` herdada do siscom antigo:
# mesmos ids, e-mails e senhas bcrypt do Devise.
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :lockable, :trackable, :timeoutable

  has_one_attached :avatar
  has_many :senhas_anteriores, class_name: "Core::SenhaAnterior", dependent: :delete_all

  scope :ativos, -> { where(status: true) }

  validate :senha_dentro_da_politica, if: -> { password.present? && will_save_change_to_encrypted_password? }

  before_update :guardar_senha_anterior, if: :will_save_change_to_encrypted_password?
  before_save :marcar_troca_de_senha, if: :will_save_change_to_encrypted_password?

  def ativo?
    status != false
  end

  def active_for_authentication?
    super && ativo?
  end

  def inactive_message
    return :inativo unless ativo?
    return mensagem_de_bloqueio if access_locked?

    super
  end

  # Mensagem de falha no login: avisa quantas tentativas restam e, no bloqueio,
  # em quanto tempo a conta é liberada.
  def unauthenticated_message
    return super if Devise.paranoid
    return mensagem_de_bloqueio if access_locked?
    return super unless failed_attempts.positive?

    I18n.t("devise.failure.tentativas_restantes", count: tentativas_restantes,
                                                    minutos: (self.class.unlock_in / 60).to_i)
  end

  def tentativas_restantes
    [ self.class.maximum_attempts - failed_attempts, 0 ].max
  end

  def minutos_para_desbloqueio
    return 0 unless access_locked?

    ((locked_at + self.class.unlock_in - Time.current) / 60).ceil.clamp(1..)
  end

  # Entra na sessão e no cookie "lembrar de mim": mudar a senha ou a
  # `versao_sessao` derruba todas as sessões abertas do usuário.
  def authenticatable_salt
    "#{super}#{versao_sessao}"
  end

  def derrubar_sessoes!
    increment!(:versao_sessao) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  def mensagem_de_bloqueio
    I18n.t("devise.failure.bloqueada", tentativas: self.class.maximum_attempts, count: minutos_para_desbloqueio)
  end

  def senha_dentro_da_politica
    Core::PoliticaDeSenha.new(self).erros(password).each { |mensagem| errors.add(:password, mensagem) }
  end

  def guardar_senha_anterior
    senhas_anteriores.create!(senha_criptografada: encrypted_password_in_database, created_at: Time.current)
    sobra = senhas_anteriores.order(created_at: :desc).offset(Core::PoliticaDeSenha::HISTORICO).pluck(:id)
    senhas_anteriores.where(id: sobra).delete_all if sobra.any?
  end

  def marcar_troca_de_senha
    self.senha_alterada_em = Time.current
  end
end
