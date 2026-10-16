# Regras de fronteira entre módulos (02-arquitetura-e-convencoes.md, seção 3):
# um módulo só chama outro pelo `<Modulo>::Api`. Do Core, além da Api, é pública
# a infraestrutura abaixo (base de services, policies e controllers).
module Fronteiras
  MODULOS = %w[Core Rh Ti Transporte Equipamentos Legado].freeze
  CORE_PUBLICO = %w[Api Resultado Autorizacao AcessoNegado PoliticaBase ExigeModulo Contexto].freeze

  Violacao = Data.define(:arquivo, :linha, :referencia) do
    def to_s = "#{arquivo}:#{linha} usa #{referencia}"
  end

  module_function

  # Arquivos de `app/` que pertencem a um módulo (pasta ou arquivo com o nome dele).
  def arquivos_do(modulo, raiz: Rails.root)
    pasta = modulo.underscore
    Dir[raiz.join("app/**/#{pasta}/**/*.{rb,erb}"), raiz.join("app/**/#{pasta}.rb")].sort
  end

  def violacoes_em(conteudo, modulo:, arquivo: "(texto)")
    outros = MODULOS - [ modulo ]
    padrao = /(?<![\w:])(?:::)?(#{outros.join('|')})::([A-Z]\w*)/

    conteudo.each_line.with_index(1).flat_map do |linha, numero|
      next [] if linha.lstrip.start_with?("#")

      linha.scan(padrao).filter_map do |outro, constante|
        next if constante == "Api"
        next if outro == "Core" && CORE_PUBLICO.include?(constante)

        Violacao.new(arquivo: arquivo, linha: numero, referencia: "#{outro}::#{constante}")
      end
    end
  end

  def violacoes(raiz: Rails.root)
    MODULOS.flat_map do |modulo|
      arquivos_do(modulo, raiz: raiz).flat_map do |arquivo|
        violacoes_em(File.read(arquivo), modulo: modulo, arquivo: Pathname(arquivo).relative_path_from(raiz).to_s)
      end
    end
  end
end
