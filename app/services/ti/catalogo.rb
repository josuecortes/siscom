module Ti
  # Os itens simples do catálogo da TI (mesma tela para os três) e como aparecem na tela.
  module Catalogo
    PERMISSAO = "ti.catalogo.gerenciar".freeze

    Definicao = Data.define(:chave, :titulo, :singular, :genero, :icone, :ajuda) do
      # Lista fixa: a chave vem da rota e nunca é transformada em nome de classe.
      def modelo
        case chave
        when "categorias" then Ti::Categoria
        when "perfis_abertura" then Ti::PerfilAbertura
        when "grupos_tecnicos" then Ti::GrupoTecnico
        end
      end

      def feminino? = genero == :f
      def artigo = feminino? ? "a" : "o"
      def novo = feminino? ? "Nova" : "Novo"
      def grupo? = chave == "grupos_tecnicos"
      def perfil? = chave == "perfis_abertura"
    end

    TODAS = [
      Definicao.new(chave: "categorias", titulo: "Categorias de solicitação", singular: "categoria", genero: :f, icone: :description,
                    ajuda: "Agrupa as solicitações na hora de abrir o chamado (ex.: Rede, Hardware, Sistemas)."),
      Definicao.new(chave: "perfis_abertura", titulo: "Perfis de abertura", singular: "perfil de abertura", genero: :m, icone: :people,
                    ajuda: "Reúne usuários e as solicitações que eles podem abrir. O perfil padrão vale para todos."),
      Definicao.new(chave: "grupos_tecnicos", titulo: "Grupos técnicos", singular: "grupo técnico", genero: :m, icone: :group,
                    ajuda: "Equipe que tria e atende um conjunto de solicitações.")
    ].index_by(&:chave).freeze

    module_function

    def buscar!(chave) = TODAS.fetch(chave.to_s)
  end
end
