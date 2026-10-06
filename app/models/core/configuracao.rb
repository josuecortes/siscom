module Core
  # Configurações do sistema e marca (porta de system_setting.rb do seed):
  # nomes no menu, no topo e no login (web e celular), ícone da marca e favicon.
  # Existe uma única linha; use Core::Configuracao.atual.
  class Configuracao < ApplicationRecord
    self.table_name = "core_configuracoes"

    # SVG fica de fora: o Active Storage não o serve como imagem (por segurança).
    TIPOS_DE_IMAGEM = %w[image/png image/webp image/jpeg image/x-icon image/vnd.microsoft.icon].freeze
    TAMANHO_MAXIMO = 1.megabyte
    TEXTOS = %i[nome_marca_web nome_marca_celular nome_cabecalho_web nome_cabecalho_celular titulo_login].freeze

    has_one_attached :icone_marca
    has_one_attached :favicon

    normalizes(*TEXTOS, with: ->(texto) { texto.to_s.squish })

    validates(*TEXTOS, presence: true, length: { maximum: 60 })
    validate :imagens_validas
    validate :senha_padrao_valida

    def self.atual
      first || create!
    end

    # Senha padrão das contas: a que a conta recebe ao ser cadastrada e quando a administração redefine a senha
    # (a pessoa é obrigada a trocar no primeiro acesso). Em branco, o sistema gera uma senha temporária aleatória.
    # Fica cifrada no banco, com uma chave derivada do segredo da aplicação.
    def senha_padrao
      return @senha_padrao if defined?(@senha_padrao)

      @senha_padrao = senha_padrao_cifrada.present? ? self.class.cofre.decrypt_and_verify(senha_padrao_cifrada) : nil
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      @senha_padrao = nil # segredo da aplicação trocado: volta a valer a senha aleatória até definirem de novo
    end

    def senha_padrao=(senha)
      @senha_padrao = senha.to_s.strip.presence
      self.senha_padrao_cifrada = @senha_padrao && self.class.cofre.encrypt_and_sign(@senha_padrao)
    end

    def self.cofre = ActiveSupport::MessageEncryptor.new(Rails.application.key_generator.generate_key("core/configuracao/senha_padrao", 32))

    private

    def senha_padrao_valida
      return if senha_padrao.blank? || !will_save_change_to_senha_padrao_cifrada?

      tamanho = ::User.password_length
      errors.add(:senha_padrao, "deve ter de #{tamanho.min} a #{tamanho.max} caracteres") unless tamanho.cover?(senha_padrao.length)
    end

    def imagens_validas
      { icone_marca: icone_marca, favicon: favicon }.each do |campo, anexo|
        next unless anexo.attached? && attachment_changes.key?(campo.to_s)

        errors.add(campo, "deve ser uma imagem PNG, WebP, JPG ou ICO") unless anexo.blob.content_type.in?(TIPOS_DE_IMAGEM)
        errors.add(campo, "deve ter no máximo 1 MB") if anexo.blob.byte_size > TAMANHO_MAXIMO
      end
    end
  end
end
