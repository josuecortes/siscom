require "net/http"

module Core
  module Mapa
    # Endereços pelo OpenStreetMap (Nominatim), como nas rotas geocode e reverse-geocode do seed:
    # `buscar` acha lugares por texto e `reverso` devolve o endereço de um ponto do mapa.
    # As respostas ficam em cache; o serviço pede um User-Agent que identifique o sistema.
    #
    #   Core::Mapa::Nominatim.buscar("Avenida FAB 96, Macapá")
    #   Core::Mapa::Nominatim.reverso(0.034934, -51.069395)
    #   # => Resultado com { rotulo:, latitude:, longitude:, cep:, logradouro:, bairro:, cidade:, uf: } (ou lista)
    module Nominatim
      BASE = "https://nominatim.openstreetmap.org".freeze
      AGENTE = "siscom-seed-ap/1.0 (Secretaria de Estado da Educacao do Amapa)".freeze
      TEMPO_LIMITE = 6
      VALIDADE_DO_CACHE = 7.days
      UFS = {
        "acre" => "AC", "alagoas" => "AL", "amapa" => "AP", "amazonas" => "AM", "bahia" => "BA", "ceara" => "CE", "distrito federal" => "DF",
        "espirito santo" => "ES", "goias" => "GO", "maranhao" => "MA", "mato grosso" => "MT", "mato grosso do sul" => "MS", "minas gerais" => "MG",
        "para" => "PA", "paraiba" => "PB", "parana" => "PR", "pernambuco" => "PE", "piaui" => "PI", "rio de janeiro" => "RJ",
        "rio grande do norte" => "RN", "rio grande do sul" => "RS", "rondonia" => "RO", "roraima" => "RR", "santa catarina" => "SC",
        "sao paulo" => "SP", "sergipe" => "SE", "tocantins" => "TO"
      }.freeze
      INDISPONIVEL = "Não foi possível consultar o mapa agora. Preencha o endereço à mão.".freeze

      module_function

      def buscar(texto, limite: 5)
        texto = texto.to_s.squish
        return Core::Resultado.falha("Informe um local para buscar no mapa.") if texto.blank?

        dados = consultar("/search", q: texto, format: "jsonv2", addressdetails: 1, countrycodes: "br", limit: limite)
        return Core::Resultado.falha(INDISPONIVEL) if dados.nil?

        Core::Resultado.sucesso(Array(dados).filter_map { |item| montar(item) })
      end

      def reverso(latitude, longitude)
        lat, lon = Float(latitude, exception: false), Float(longitude, exception: false)
        return Core::Resultado.falha("Ponto do mapa inválido.") unless lat&.between?(-90, 90) && lon&.between?(-180, 180)

        dados = consultar("/reverse", lat: lat.round(6), lon: lon.round(6), format: "jsonv2", addressdetails: 1, zoom: 18)
        return Core::Resultado.falha(INDISPONIVEL) if dados.nil?

        endereco = montar(dados.merge("lat" => lat.round(6).to_s, "lon" => lon.round(6).to_s))
        endereco ? Core::Resultado.sucesso(endereco) : Core::Resultado.falha("Não achei um endereço para este ponto. Preencha à mão.")
      end

      def consultar(caminho, **parametros)
        uri = URI("#{BASE}#{caminho}")
        uri.query = URI.encode_www_form(parametros.merge("accept-language": "pt-BR"))
        Rails.cache.fetch("core/mapa/#{uri.request_uri}", expires_in: VALIDADE_DO_CACHE, skip_nil: true) do
          resposta = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TEMPO_LIMITE, read_timeout: TEMPO_LIMITE) do |http|
            http.get(uri.request_uri, "User-Agent" => AGENTE, "Accept" => "application/json")
          end
          resposta.is_a?(Net::HTTPSuccess) ? JSON.parse(resposta.body) : nil
        end
      rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError
        nil
      end

      def montar(item)
        partes = item["address"]
        return nil unless item["lat"].present? && item["lon"].present? && partes.is_a?(Hash)

        cep = partes["postcode"].to_s.gsub(/\D/, "")
        {
          rotulo: item["display_name"].to_s, latitude: item["lat"].to_f.round(6), longitude: item["lon"].to_f.round(6),
          cep: (cep.length == 8 ? "#{cep[0, 5]}-#{cep[5, 3]}" : ""),
          logradouro: partes["road"].to_s, bairro: (partes["suburb"] || partes["neighbourhood"] || partes["quarter"]).to_s,
          cidade: (partes["city"] || partes["town"] || partes["village"] || partes["municipality"]).to_s, uf: uf_de(partes)
        }
      end

      def uf_de(partes)
        codigo = partes["ISO3166-2-lvl4"].to_s.split("-").last.to_s.upcase
        return codigo if codigo.length == 2

        UFS[I18n.transliterate(partes["state"].to_s).downcase].to_s
      end
    end
  end
end
