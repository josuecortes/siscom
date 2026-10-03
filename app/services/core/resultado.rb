module Core
  # Retorno padrão dos services (`.call`): sucesso ou falha, com o objeto
  # envolvido e a lista de erros (mensagens prontas para exibir).
  #
  #   resultado = Rh::Pessoas::Criar.call(...)
  #   if resultado.sucesso? then resultado.objeto else resultado.erros end
  class Resultado
    attr_reader :objeto, :erros

    def self.sucesso(objeto = nil)
      new(sucesso: true, objeto: objeto)
    end

    # `erros` aceita String, Array de Strings, ActiveModel::Errors ou um
    # registro inválido (usa as mensagens dele e o guarda como objeto).
    def self.falha(erros, objeto: nil)
      if erros.respond_to?(:errors) && erros.errors.respond_to?(:full_messages)
        objeto ||= erros
        erros = erros.errors
      end
      erros = erros.full_messages if erros.respond_to?(:full_messages)

      new(sucesso: false, objeto: objeto, erros: Array(erros))
    end

    def initialize(sucesso:, objeto: nil, erros: [])
      @sucesso = sucesso
      @objeto = objeto
      @erros = erros.map(&:to_s).freeze
      freeze
    end

    def sucesso? = @sucesso
    def falha? = !@sucesso

    def mensagem_de_erro
      erros.to_sentence
    end
  end
end
