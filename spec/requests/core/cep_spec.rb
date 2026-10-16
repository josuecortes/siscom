require "rails_helper"

RSpec.describe "Consulta de CEP" do
  before do
    stub_request(:get, "https://viacep.com.br/ws/68900073/json/")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { logradouro: "Avenida FAB", bairro: "Central", localidade: "Macapá", uf: "AP" }.to_json)
  end

  it "exige login" do
    get cep_path("68900073")

    expect(response).to have_http_status(:unauthorized)
  end

  it "devolve o endereço em JSON, com ou sem hífen" do
    sign_in create(:user)

    get cep_path("68900-073")

    expect(response.parsed_body).to include("logradouro" => "Avenida FAB", "bairro" => "Central", "cidade" => "Macapá", "uf" => "AP", "cep" => "68900-073")
  end

  it "responde 404 quando nenhum serviço conhece o CEP" do
    sign_in create(:user)
    stub_request(:get, "https://viacep.com.br/ws/11111111/json/").to_return(status: 200, body: { erro: true }.to_json)
    stub_request(:get, "https://brasilapi.com.br/api/cep/v1/11111111").to_return(status: 404, body: "{}")
    stub_request(:get, "https://opencep.com/v1/11111111").to_return(status: 404, body: "{}")

    get cep_path("11111111")

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body).to eq("erro" => "CEP não encontrado.")
  end
end
