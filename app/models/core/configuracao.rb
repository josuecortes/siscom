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

    def self.atual
      first || create!
    end

    private

    def imagens_validas
      { icone_marca: icone_marca, favicon: favicon }.each do |campo, anexo|
        next unless anexo.attached? && attachment_changes.key?(campo.to_s)

        errors.add(campo, "deve ser uma imagem PNG, WebP, JPG ou ICO") unless anexo.blob.content_type.in?(TIPOS_DE_IMAGEM)
        errors.add(campo, "deve ter no máximo 1 MB") if anexo.blob.byte_size > TAMANHO_MAXIMO
      end
    end
  end
end
