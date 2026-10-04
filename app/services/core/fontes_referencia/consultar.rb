module Core
  module FontesReferencia
    # Opções de uma fonte para um campo de busca/seleção:
    #   Core::FontesReferencia::Consultar.call(chave: "core_usuarios", termo: "maria")
    #   # => [{ valor: 12, rotulo: "MARIA OLIVEIRA", subtitulo: "maria@seed.ap.gov.br" }, ...]
    class Consultar
      LIMITE = 20

      def self.call(...) = new(...).call

      # Com `valor`, devolve só a opção com aquele valor (para conferir e guardar uma escolha).
      def initialize(chave:, termo: nil, limite: LIMITE, valor: nil)
        @chave = chave.to_s
        @valor = valor
        @termo = termo.to_s.squish
        @limite = limite.to_i.clamp(1, 50)
      end

      def call
        fonte = Core::FonteReferencia.ativo.find_by(chave: @chave)
        return [] unless fonte&.definicao

        registros = Entidades.registros(fonte.modulo, fonte.entidade)
        tabela = registros.klass.arel_table
        registros = filtrar(registros, tabela, fonte) if @termo.present?
        unless @valor.nil?
          valor = valor_convertido(registros.klass, fonte.campo_valor)
          return [] if valor.nil?

          registros = registros.where(tabela[fonte.campo_valor].eq(valor))
        end
        colunas = [ fonte.campo_valor, fonte.campo_rotulo, fonte.campo_subtitulo ].compact

        registros.reorder(tabela[fonte.campo_rotulo].asc, tabela[fonte.campo_valor].asc).limit(@limite)
                 .pluck(*colunas.map { |coluna| tabela[coluna] })
                 .map { |valor, rotulo, subtitulo| { valor: valor, rotulo: rotulo, subtitulo: subtitulo } }
      end

      private

      # O valor vem do navegador: para coluna numérica, só passa se for número.
      def valor_convertido(modelo, campo)
        modelo.columns_hash[campo]&.type == :integer ? Integer(@valor.to_s, exception: false) : @valor.to_s
      end

      # Os nomes de campo já foram validados contra a lista da entidade; ainda assim
      # a consulta é montada com Arel, sem interpolar texto em SQL.
      def filtrar(registros, tabela, fonte)
        padrao = "%#{ActiveRecord::Base.sanitize_sql_like(@termo)}%"
        condicoes = fonte.campos_busca.map { |campo| tabela[campo].matches(padrao) }

        registros.where(condicoes.reduce(:or))
      end
    end
  end
end
