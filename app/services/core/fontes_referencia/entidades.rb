module Core
  module FontesReferencia
    # Entidades que podem virar fonte de referência. Cada módulo publica as suas
    # pela própria Api, com dois métodos opcionais:
    #
    #   <Modulo>::Api.entidades_publicaveis
    #     # => { "usuarios" => { nome: "Administração > Usuários", descricao: "...", campo_rotulo: "nome",
    #     #                      campo_valor: "id", campo_subtitulo: "email", campos_busca: %w[nome email],
    #     #                      campos: %w[id nome email] } }
    #   <Modulo>::Api.registros_da_entidade("usuarios")   # => relação já filtrada (ex.: só ativos)
    #
    # O Core nunca toca direto na tabela de outro módulo.
    module Entidades
      Definicao = Data.define(:modulo, :entidade, :nome, :descricao, :campo_rotulo, :campo_valor, :campo_subtitulo,
                              :campos_busca, :campos) do
        def chave_padrao = "#{modulo}_#{entidade}"
      end

      module_function

      def todas
        Core::Catalogo.modulos.flat_map do |modulo|
          api = api_do(modulo.chave)
          next [] unless api.respond_to?(:entidades_publicaveis)

          api.entidades_publicaveis.map do |entidade, dados|
            Definicao.new(modulo: modulo.chave, entidade: entidade.to_s, nome: dados.fetch(:nome), descricao: dados[:descricao],
                          campo_rotulo: dados.fetch(:campo_rotulo), campo_valor: dados.fetch(:campo_valor, "id"),
                          campo_subtitulo: dados[:campo_subtitulo], campos_busca: dados.fetch(:campos_busca).map(&:to_s),
                          campos: dados.fetch(:campos).map(&:to_s))
          end
        end
      end

      def buscar(modulo, entidade)
        todas.find { |definicao| definicao.modulo == modulo.to_s && definicao.entidade == entidade.to_s }
      end

      def registros(modulo, entidade)
        api_do(modulo).registros_da_entidade(entidade.to_s)
      end

      def api_do(modulo) = "#{modulo.to_s.camelize}::Api".constantize
    end
  end
end
