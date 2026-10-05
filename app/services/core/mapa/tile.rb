require "net/http"

module Core
  module Mapa
    # Imagem de um quadradinho do mapa (tile), buscada no OpenStreetMap e, se ele falhar, num segundo
    # provedor (porta da rota map-tiles do seed). O navegador pede ao siscom, e não direto ao provedor:
    # assim a política de segurança (CSP) continua só com a própria origem, e a imagem fica em cache.
    module Tile
      PROVEDORES = [ "https://tile.openstreetmap.org/%<z>d/%<x>d/%<y>d.png", "https://a.basemaps.cartocdn.com/light_all/%<z>d/%<x>d/%<y>d.png" ].freeze
      TEMPO_LIMITE = 6
      VALIDADE_DO_CACHE = 7.days
      ZOOM_MAXIMO = 19

      module_function

      # Devolve { tipo:, bytes: } ou nil (coordenadas inválidas ou provedores fora do ar).
      def buscar(z, x, y)
        z, x, y = [ z, x, y ].map { |valor| Integer(valor.to_s, 10, exception: false) }
        return nil unless z&.between?(0, ZOOM_MAXIMO) && x && y && [ x, y ].all? { |valor| valor.between?(0, (2**z) - 1) }

        Rails.cache.fetch("core/mapa/tile/#{z}/#{x}/#{y}", expires_in: VALIDADE_DO_CACHE, skip_nil: true) do
          PROVEDORES.lazy.filter_map { |modelo| baixar(format(modelo, z: z, x: x, y: y)) }.first
        end
      end

      def baixar(url)
        uri = URI(url)
        resposta = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: TEMPO_LIMITE, read_timeout: TEMPO_LIMITE) do |http|
          http.get(uri.request_uri, "User-Agent" => Nominatim::AGENTE, "Accept" => "image/png,image/*")
        end
        return nil unless resposta.is_a?(Net::HTTPSuccess) && resposta["Content-Type"].to_s.start_with?("image/")

        { tipo: resposta["Content-Type"], bytes: resposta.body.b }
      rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError
        nil
      end
    end
  end
end
