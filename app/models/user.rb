# Usuário global do sistema (dono: Core). Tabela `users` herdada do siscom antigo:
# mesmos ids, e-mails e senhas bcrypt do Devise.
class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :lockable, :trackable, :timeoutable

  has_one_attached :avatar
  has_many :inscricoes_push, class_name: "Core::InscricaoPush", dependent: :delete_all
  has_many :notificacoes, class_name: "Core::Notificacao", dependent: :delete_all
  has_many :senhas_anteriores, class_name: "Core::SenhaAnterior", dependent: :delete_all

  scope :ativos, -> { where(status: true) }

  # Regras herdadas do siscom antigo: nome obrigatório, único e em maiúsculas.
  # Só valem quando o nome muda, para não travar registros antigos repetidos.
  normalizes :nome, with: ->(nome) { nome.squish.upcase }
  validates :nome, presence: true
  validates :nome, uniqueness: { case_sensitive: false }, if: :will_save_change_to_nome?

  # Senha temporária em texto, disponível só logo após criar/redefinir (nunca é gravada).
  attr_accessor :senha_temporaria

  AVATAR_TIPOS = %w[image/png image/jpeg image/webp].freeze
  AVATAR_TAMANHO_MAXIMO = 5.megabytes

  validate :avatar_valido, if: -> { attachment_changes.key?("avatar") }
  validate :senha_dentro_da_politica, if: -> { password.present? && will_save_change_to_encrypted_password? }

  before_update :guardar_senha_anterior, if: :will_save_change_to_encrypted_password?
  before_save :marcar_troca_de_senha, if: :will_save_change_to_encrypted_password?

  scope :inativos, -> { where(status: false) }
  scope :buscar, lambda { |termo|
    padrao = "%#{sanitize_sql_like(termo.to_s.squish)}%"
    where("users.nome ILIKE :p OR users.email ILIKE :p", p: padrao)
  }

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

  def avatar_valido
    return unless avatar.attached?

    errors.add(:avatar, "deve ser uma imagem PNG, JPG ou WebP") unless avatar.blob.content_type.in?(AVATAR_TIPOS)
    errors.add(:avatar, "deve ter no máximo 5 MB") if avatar.blob.byte_size > AVATAR_TAMANHO_MAXIMO
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
