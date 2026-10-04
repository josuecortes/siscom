module Core
  # Catálogo de módulos: lê `config/modulos/<modulo>.yml` (permissões, papéis,
  # quem concede o quê e itens de menu) e valida a consistência na carga.
  #
  #   Core::Catalogo.modulo(:rh).permissoes_do_papel(:operador)
  #   Core::Catalogo.permissao?("rh.pessoas.editar")
  class Catalogo
    class Erro < StandardError; end

    PASTA_PADRAO = Rails.root.join("config/modulos")
    TODAS = "*".freeze

    Papel = Data.define(:chave, :nome, :permissoes, :automatico) do
      def automatico? = automatico
    end

    # `minha_area`: o item aparece no grupo "Minha área" (o dia a dia de qualquer usuário), fora do grupo do módulo.
    ItemMenu = Data.define(:rotulo, :rota, :permissao, :icone, :grupo, :minha_area)

    Modulo = Data.define(:chave, :nome, :icone, :permissoes, :papeis, :concessao, :menu) do
      def permissao?(permissao) = permissoes.key?(permissao.to_s)
      def papel(chave) = papeis[chave.to_s]
      def papel?(chave) = papeis.key?(chave.to_s)

      # Permissões (chaves locais, sem o prefixo do módulo) de um papel.
      def permissoes_do_papel(chave)
        papel(chave)&.permissoes || Set.new
      end

      def papeis_automaticos = papeis.values.select(&:automatico?)

      # Papéis que alguém com o papel `chave` pode conceder a outros usuários.
      def papeis_concediveis_por(chave) = concessao.fetch(chave.to_s, [])
    end

    class << self
      delegate :modulos, :modulo, :modulo!, :modulo?, :permissao?, :separar, to: :atual

      def atual
        @atual ||= new(PASTA_PADRAO)
      end

      def recarregar!
        @atual = nil
      end
    end

    def initialize(pasta)
      @modulos = Pathname(pasta).glob("*.yml").sort.to_h do |arquivo|
        chave = arquivo.basename(".yml").to_s
        [ chave, montar(chave, YAML.safe_load_file(arquivo) || {}) ]
      end.freeze
    end

    def modulos = @modulos.values
    def modulo(chave) = @modulos[chave.to_s]
    def modulo?(chave) = @modulos.key?(chave.to_s)

    def modulo!(chave)
      modulo(chave) || raise(Erro, "módulo desconhecido: #{chave}")
    end

    # "rh.pessoas.editar" => ["rh", "pessoas.editar"]
    def separar(permissao)
      permissao.to_s.split(".", 2)
    end

    # Aceita a chave completa ("rh.pessoas.editar").
    def permissao?(permissao)
      chave_modulo, local = separar(permissao)
      modulo(chave_modulo)&.permissao?(local) || false
    end

    private

    def montar(chave, dados)
      erro!(chave, "falta o nome") if dados["nome"].blank?

      permissoes = (dados["permissoes"] || {}).transform_keys(&:to_s).freeze
      papeis = montar_papeis(chave, dados["papeis"] || {}, permissoes)

      Modulo.new(
        chave: chave,
        nome: dados["nome"],
        icone: dados["icone"],
        permissoes: permissoes,
        papeis: papeis,
        concessao: montar_concessao(chave, dados["concessao"] || {}, papeis),
        menu: montar_menu(chave, dados["menu"] || [], permissoes)
      )
    end

    def montar_papeis(chave, dados, permissoes)
      dados.to_h do |chave_papel, definicao|
        lista = definicao["permissoes"]
        lista = permissoes.keys if lista == TODAS
        lista = Array(lista).map(&:to_s)

        desconhecidas = lista - permissoes.keys
        erro!(chave, "papel #{chave_papel} usa permissões inexistentes: #{desconhecidas.join(', ')}") if desconhecidas.any?
        erro!(chave, "papel #{chave_papel} sem nome") if definicao["nome"].blank?

        [ chave_papel.to_s, Papel.new(chave: chave_papel.to_s, nome: definicao["nome"], permissoes: lista.to_set.freeze,
                                      automatico: definicao["automatico"] == true) ]
      end.freeze
    end

    def montar_concessao(chave, dados, papeis)
      dados.to_h do |quem, quais|
        quais = Array(quais).map(&:to_s)
        desconhecidos = ([ quem.to_s ] + quais) - papeis.keys
        erro!(chave, "concessão cita papéis inexistentes: #{desconhecidos.join(', ')}") if desconhecidos.any?

        [ quem.to_s, quais.freeze ]
      end.freeze
    end

    def montar_menu(chave, itens, permissoes)
      itens.map do |item|
        permissao = item["permissao"]&.to_s
        erro!(chave, "menu #{item['rotulo']} usa permissão inexistente: #{permissao}") if permissao && !permissoes.key?(permissao)
        erro!(chave, "item de menu sem rótulo ou rota") if item["rotulo"].blank? || item["rota"].blank?

        ItemMenu.new(rotulo: item["rotulo"], rota: item["rota"].to_s, permissao: permissao, icone: item["icone"], grupo: item["grupo"],
                     minha_area: item["minha_area"] == true)
      end.freeze
    end

    def erro!(chave, mensagem)
      raise Erro, "config/modulos/#{chave}.yml: #{mensagem}"
    end
  end
end
