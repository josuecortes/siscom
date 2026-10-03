module Rh
  # As cinco tabelas de referência do RH e como aparecem na tela.
  module Tabelas
    Definicao = Data.define(:chave, :titulo, :singular, :genero, :com_descricao) do
      # Lista fixa: a chave vem da rota e nunca é transformada em nome de classe.
      def modelo
        case chave
        when "tipos_vinculo" then Rh::TipoVinculo
        when "cargos" then Rh::Cargo
        when "funcoes" then Rh::Funcao
        when "tipos_unidade" then Rh::TipoUnidade
        when "tipos_local" then Rh::TipoLocal
        end
      end

      def feminino? = genero == :f
      def artigo = feminino? ? "a" : "o"
      def novo = feminino? ? "Nova" : "Novo"
    end

    TODAS = [
      Definicao.new(chave: "tipos_vinculo", titulo: "Vínculos", singular: "vínculo", genero: :m, com_descricao: false),
      Definicao.new(chave: "cargos", titulo: "Cargos", singular: "cargo", genero: :m, com_descricao: false),
      Definicao.new(chave: "funcoes", titulo: "Funções de lotação", singular: "função", genero: :f, com_descricao: true),
      Definicao.new(chave: "tipos_unidade", titulo: "Tipos de unidade", singular: "tipo de unidade", genero: :m, com_descricao: true),
      Definicao.new(chave: "tipos_local", titulo: "Locais físicos", singular: "local físico", genero: :m, com_descricao: true)
    ].index_by(&:chave).freeze

    NAO_INFORMADO = "NÃO INFORMADO".freeze

    module_function

    def buscar!(chave) = TODAS.fetch(chave.to_s)

    # Vínculos e locais não existiam no siscom antigo: começam com a opção "Não informado".
    def garantir_padroes
      [ Rh::TipoVinculo, Rh::TipoLocal ].each { |modelo| modelo.find_or_create_by!(nome: NAO_INFORMADO) }
    end
  end
end
