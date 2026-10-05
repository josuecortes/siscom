require "rails_helper"

RSpec.describe Core::Mapa, :com_cache do
  let(:json) { { "Content-Type" => "application/json" } }
  let(:lugar) do
    { "display_name" => "Avenida FAB, Central, Macapá, Amapá, 68900-073, Brasil", "lat" => "0.0349341", "lon" => "-51.0693952",
      "address" => { "road" => "Avenida FAB", "suburb" => "Central", "city" => "Macapá", "state" => "Amapá", "postcode" => "68900-073" } }
  end

  describe Core::Mapa::Nominatim do
    it "busca um lugar por texto e devolve o endereço separado, com a UF" do
      pedido = stub_request(:get, "https://nominatim.openstreetmap.org/search")
               .with(query: hash_including("q" => "Avenida FAB 96, Macapá", "countrycodes" => "br"), headers: { "User-Agent" => /siscom/ })
               .to_return(status: 200, headers: json, body: [ lugar ].to_json)

      2.times { described_class.buscar("  Avenida FAB 96,   Macapá ") }
      resultado = described_class.buscar("Avenida FAB 96, Macapá")

      expect(resultado.objeto).to eq([ { rotulo: lugar["display_name"], latitude: 0.034934, longitude: -51.069395, cep: "68900-073",
                                         logradouro: "Avenida FAB", bairro: "Central", cidade: "Macapá", uf: "AP" } ])
      expect(pedido).to have_been_requested.once # as repetições vêm do cache
    end

    it "devolve o endereço de um ponto do mapa" do
      stub_request(:get, "https://nominatim.openstreetmap.org/reverse").with(query: hash_including("lat" => "0.034934", "lon" => "-51.069395"))
                                                                         .to_return(status: 200, headers: json, body: lugar.to_json)

      expect(described_class.reverso("0.0349341", "-51.0693952").objeto).to include(logradouro: "Avenida FAB", cidade: "Macapá", uf: "AP", latitude: 0.034934)
    end

    it "falha com mensagem clara quando o serviço não responde ou a entrada é ruim" do
      stub_request(:get, /nominatim/).to_timeout

      expect(described_class.buscar("Macapá").mensagem_de_erro).to include("Não foi possível consultar o mapa agora")
      expect(described_class.buscar(" ")).to be_falha
      expect(described_class.reverso("abc", "200")).to be_falha
    end
  end

  describe Core::Mapa::Tile do
    it "baixa a imagem do OpenStreetMap, guarda em cache e usa o segundo provedor se o primeiro falhar" do
      osm = stub_request(:get, "https://tile.openstreetmap.org/15/11736/16379.png").to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: "PNG1")
      stub_request(:get, "https://tile.openstreetmap.org/15/1/2.png").to_return(status: 503)
      stub_request(:get, "https://a.basemaps.cartocdn.com/light_all/15/1/2.png").to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: "PNG2")

      2.times { described_class.buscar("15", "11736", "16379") }

      expect(described_class.buscar(15, 11_736, 16_379)).to eq(tipo: "image/png", bytes: "PNG1")
      expect(osm).to have_been_requested.once
      expect(described_class.buscar(15, 1, 2)[:bytes]).to eq("PNG2")
    end

    it "recusa coordenadas fora do mapa sem chamar ninguém" do
      expect([ described_class.buscar(25, 1, 1), described_class.buscar(3, 9, 1), described_class.buscar("a", 1, 1) ]).to all(be_nil)
    end
  end

  describe "endpoints", type: :request do
    it "exigem login e respondem em JSON e imagem" do
      get mapa_buscar_path, params: { q: "Macapá" }
      expect(response).to have_http_status(:unauthorized).or redirect_to(new_user_session_path)

      sign_in create(:user)
      stub_request(:get, /nominatim.*search/).to_return(status: 200, headers: json, body: [ lugar ].to_json)
      stub_request(:get, /nominatim.*reverse/).to_return(status: 200, headers: json, body: lugar.to_json)
      stub_request(:get, "https://tile.openstreetmap.org/15/11736/16379.png").to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: "PNG")

      get mapa_buscar_path, params: { q: "Macapá" }
      expect(response.parsed_body["lugares"].first).to include("cidade" => "Macapá")
      get mapa_reverso_path, params: { lat: "0.0349", lon: "-51.0693" }
      expect(response.parsed_body["endereco"]).to include("logradouro" => "Avenida FAB")
      get mapa_tile_path(z: 15, x: 11_736, y: 16_379)
      expect([ response.media_type, response.body ]).to eq([ "image/png", "PNG" ])
      get mapa_tile_path(z: 3, x: 99, y: 1)
      expect(response).to have_http_status(:not_found)
    end
  end
end
