require "net/http"

module Core
  module Cep
    # Consulta um CEP em três serviços públicos, em sequência: se um não responde ou não
    # conhece o CEP, tenta o próximo. O resultado fica em cache.
    #
    #   Core::Cep::Consultar.call("68900-073")
    #   # => Resultado com { cep:, logradouro:, bairro:, cidade:, uf:, fonte: }
    class Consultar
      TEMPO_LIMITE = 4 # segundos por serviço
      VALIDADE_DO_CACHE = 30.days

      SERVICOS = [
        { nome: "ViaCEP", url: "https://viacep.com.br/ws/%s/json/",
          campos: { logradouro: "logradouro", bairro: "bairro", cidade: "localidade", uf: "uf" }, sem_resultado: ->(dados) { dados["erro"].present? } },
        { nome: "BrasilAPI", url: "https://brasilapi.com.br/api/cep/v1/%s",
          campos: { logradouro: "street", bairro: "neighborhood", cidade: "city", uf: "state" }, sem_resultado: ->(dados) { dados["city"].blank? } },
        { nome: "OpenCEP", url: "https://opencep.com/v1/%s",
          campos: { logradouro: "logradouro", bairro: "bairro", cidade: "localidade", uf: "uf" }, sem_resultado: ->(dados) { dados["localidade"].blank? } }
      ].freeze

      def self.call(cep) = new(cep).call

      def initialize(cep)
        @cep = cep.to_s.gsub(/\D/, "")
      end

      def call
        return Core::Resultado.falha("CEP inválido. Informe 8 dígitos.") unless @cep.length == 8

        endereco = Rails.cache.fetch("core/cep/#{@cep}", expires_in: VALIDADE_DO_CACHE, skip_nil: true) { procurar }
        return Core::Resultado.sucesso(endereco) if endereco

        Core::Resultado.falha(@indisponivel ? "Serviço de CEP indisponível no momento. Preencha o endereço à mão." : "CEP não encontrado.")
      end

      private

      def procurar
        respostas = SERVICOS.map do |servico|
          dados = buscar(servico)
          next :fora_do_ar if dados.nil?
          next :sem_resultado if servico[:sem_resultado].call(dados)

          return montar(servico, dados)
        end

        @indisponivel = respostas.all?(:fora_do_ar)
        nil
      end

      def buscar(servico)
        uri = URI(format(servico[:url], @cep))
        resposta = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TEMPO_LIMITE, read_timeout: TEMPO_LIMITE) do |http|
          http.get(uri.request_uri, "Accept" => "application/json")
        end
        return {} if resposta.code.in?(%w[400 404])
        return nil unless resposta.is_a?(Net::HTTPSuccess)

        JSON.parse(resposta.body)
      rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError
        nil
      end

      def montar(servico, dados)
        servico[:campos].transform_values { |chave| dados[chave].to_s.strip }
                        .merge(cep: "#{@cep[0, 5]}-#{@cep[5, 3]}", fonte: servico[:nome])
                        .tap { |endereco| endereco[:uf] = endereco[:uf].upcase }
      end
    end
  end
end
