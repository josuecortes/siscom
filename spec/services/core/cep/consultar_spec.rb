require "rails_helper"

RSpec.describe Core::Cep::Consultar, :com_cache do
  let(:viacep) { "https://viacep.com.br/ws/68900073/json/" }
  let(:brasilapi) { "https://brasilapi.com.br/api/cep/v1/68900073" }
  let(:opencep) { "https://opencep.com/v1/68900073" }
  let(:json) { { "Content-Type" => "application/json" } }

  it "usa o primeiro serviço que conhece o CEP" do
    stub_request(:get, viacep).to_return(status: 200, headers: json,
                                         body: { logradouro: "Avenida FAB", bairro: "Central", localidade: "Macapá", uf: "ap" }.to_json)

    endereco = described_class.call("68900-073").objeto

    expect(endereco).to eq(logradouro: "Avenida FAB", bairro: "Central", cidade: "Macapá", uf: "AP", cep: "68900-073", fonte: "ViaCEP")
  end

  it "passa para o segundo e o terceiro serviço quando os anteriores falham ou não conhecem o CEP" do
    stub_request(:get, viacep).to_timeout
    stub_request(:get, brasilapi).to_return(status: 404, headers: json, body: { message: "CEP não encontrado" }.to_json)
    stub_request(:get, opencep).to_return(status: 200, headers: json,
                                          body: { logradouro: "Rua A", bairro: "Centro", localidade: "Santana", uf: "AP" }.to_json)

    resultado = described_class.call("68900073")

    expect(resultado.objeto).to include(cidade: "Santana", fonte: "OpenCEP")
  end

  it "entende a resposta da BrasilAPI" do
    stub_request(:get, viacep).to_return(status: 200, headers: json, body: { erro: true }.to_json)
    stub_request(:get, brasilapi).to_return(status: 200, headers: json,
                                            body: { street: "Rua B", neighborhood: "Trem", city: "Macapá", state: "AP" }.to_json)

    expect(described_class.call("68900073").objeto).to include(logradouro: "Rua B", bairro: "Trem", fonte: "BrasilAPI")
  end

  it "diz que o CEP não existe quando nenhum serviço o conhece" do
    stub_request(:get, viacep).to_return(status: 200, headers: json, body: { erro: true }.to_json)
    stub_request(:get, brasilapi).to_return(status: 404, body: "{}")
    stub_request(:get, opencep).to_return(status: 404, body: "{}")

    expect(described_class.call("68900073").erros).to eq([ "CEP não encontrado." ])
  end

  it "diz que o serviço está indisponível quando os três falham" do
    [ viacep, brasilapi, opencep ].each { |url| stub_request(:get, url).to_return(status: 500) }

    expect(described_class.call("68900073").erros).to eq([ "Serviço de CEP indisponível no momento. Preencha o endereço à mão." ])
  end

  it "recusa CEP incompleto sem consultar ninguém" do
    expect(described_class.call("6890").erros).to eq([ "CEP inválido. Informe 8 dígitos." ])
    expect(WebMock).not_to have_requested(:get, /cep/)
  end

  it "guarda o resultado em cache" do
    consulta = stub_request(:get, viacep).to_return(status: 200, headers: json,
                                                    body: { logradouro: "Avenida FAB", bairro: "Central", localidade: "Macapá", uf: "AP" }.to_json)

    2.times { described_class.call("68900073") }

    expect(consulta).to have_been_requested.once
  end
end
