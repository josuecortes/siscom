module Ti
  module Chamados
    # Confere as respostas do formulário de uma solicitação, campo a campo, e prepara o que
    # será guardado. Não grava nada.
    #
    #   respostas = Ti::Chamados::Respostas.new(solicitacao, params[:campos])
    #   respostas.erros   # => { "cpf" => "deve ser preenchido" }
    #   respostas.valores # => [{ campo:, texto:, json:, arquivos: }]
    class Respostas
      attr_reader :erros, :valores

      # `anexos_mantidos`: ids dos campos de arquivo que já têm anexo no chamado (na edição): sem arquivo
      # novo, o anexo antigo fica e o campo conta como preenchido.
      def initialize(solicitacao, entradas, anexos_mantidos: [])
        @anexos_mantidos = anexos_mantidos
        # `entradas` pode ser um Hash ou os parâmetros da requisição: só as chaves dos campos são lidas.
        @entradas = entradas || {}
        @erros = {}
        @valores = solicitacao.campos.ativo.ordenados.filter_map { |campo| conferir(campo) }
      end

      def validas? = @erros.empty?

      # O que o usuário digitou em um campo, para mostrar de volta no formulário.
      def entrada(campo)
        valor = @entradas[campo.chave]
        valor.nil? && @entradas.is_a?(Hash) ? @entradas[campo.chave.to_sym] : valor
      end

      private

      def conferir(campo)
        bruto = entrada(campo)
        valor = send(:"ler_#{metodo(campo)}", campo, bruto)
        return nil if @erros.key?(campo.chave)
        return { campo: campo, manter: true } if valor.nil? && @anexos_mantidos.include?(campo.id)

        if vazio?(valor)
          @erros[campo.chave] = "deve ser preenchido" if campo.obrigatorio?
          return nil
        end
        valor.merge(campo: campo)
      end

      def metodo(campo)
        case campo.tipo
        when "texto", "texto_longo" then "texto"
        when "selecao", "selecao_unica" then "opcao"
        when "selecao_multipla" then "opcoes"
        when "arquivo", "arquivos" then "arquivos"
        when "busca", "busca_multipla" then "busca"
        else campo.tipo
        end
      end

      def vazio?(valor) = valor.nil? || (valor[:texto].blank? && Array(valor[:arquivos]).empty?)

      def ler_texto(_campo, bruto) = { texto: bruto.to_s.strip.presence }

      def ler_opcao(campo, bruto)
        escolha = bruto.to_s.strip
        return nil if escolha.blank?
        return erro(campo, "deve ser uma das opções") unless campo.opcoes.include?(escolha)

        { texto: escolha }
      end

      def ler_opcoes(campo, bruto)
        escolhas = Array(bruto).map { |item| item.to_s.strip }.compact_blank.uniq
        return nil if escolhas.empty?
        return erro(campo, "deve ter só opções da lista") unless (escolhas - campo.opcoes).empty?

        { texto: escolhas.join(", "), json: { "opcoes" => escolhas } }
      end

      def ler_sim_nao(campo, bruto)
        return nil if bruto.blank?
        return erro(campo, "deve ser Sim ou Não") unless %w[sim nao].include?(bruto.to_s)

        { texto: (bruto.to_s == "sim" ? "Sim" : "Não") }
      end

      def ler_data(campo, bruto)
        return nil if bruto.blank?

        data = DataBr.interpretar(bruto)
        data ? { texto: DataBr.formatar(data), json: { "data" => data.iso8601 } } : erro(campo, "deve ser uma data válida (dd/mm/aaaa)")
      end

      def ler_numero(campo, bruto)
        texto = bruto.to_s.strip.tr(",", ".")
        return nil if texto.blank?

        Float(texto, exception: false) ? { texto: bruto.to_s.strip } : erro(campo, "deve ser um número")
      end

      def ler_arquivos(campo, bruto)
        # Sem Array(): um arquivo responde a to_a (as linhas dele).
        arquivos = (bruto.is_a?(Array) ? bruto : [ bruto ]).select { |item| item.respond_to?(:original_filename) }
        arquivos = arquivos.first(1) if campo.tipo == "arquivo"
        return nil if arquivos.empty?
        return erro(campo, "deve ter no máximo #{Anexo::LIMITE} por arquivo") if arquivos.any? { |arquivo| Anexo.grande?(arquivo) }

        { texto: arquivos.map(&:original_filename).join(", "), arquivos: arquivos }
      end

      # O valor escolhido é conferido na fonte de referência; guarda-se o valor e o nome exibido.
      def ler_busca(campo, bruto)
        return nil if bruto.blank?

        opcao = Core::Api.opcao_da_fonte(campo.fonte, bruto)
        opcao ? { texto: opcao[:rotulo].to_s, json: { "valor" => opcao[:valor], "rotulo" => opcao[:rotulo] } } : erro(campo, "deve ser escolhido na lista")
      end

      def erro(campo, mensagem)
        @erros[campo.chave] = mensagem
        nil
      end
    end
  end
end
