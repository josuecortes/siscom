require "rails_helper"

RSpec.describe Core::Notificacoes::EnviarPushJob do
  include ActiveJob::TestHelper

  let(:maria) { create(:user) }
  # Par de chaves válido de um "navegador" de mentira, para a criptografia do Web Push funcionar.
  let(:navegador) { WebPush.generate_key }
  let(:endpoint) { "https://push.exemplo.test/aparelho-1" }
  let!(:inscricao) do
    maria.inscricoes_push.create!(endpoint: endpoint, p256dh: navegador.public_key, auth: Base64.urlsafe_encode64(SecureRandom.bytes(16)))
  end

  before { allow(Turbo::StreamsChannel).to receive_messages(broadcast_replace_to: nil, broadcast_append_to: nil) }

  def notificar
    Core::Notificacoes::Criar.call(destinatarios: maria, evento: "core.acesso.papel_concedido", titulo: "Novo papel", ator: nil).first
  end

  it "é enfileirado quando uma notificação é criada" do
    expect { notificar }.to have_enqueued_job(described_class)
  end

  it "envia para o aparelho inscrito, criptografado e assinado" do
    envio = stub_request(:post, endpoint).to_return(status: 201)

    perform_enqueued_jobs { notificar }

    expect(envio).to have_been_requested.once
    expect(WebMock).to(have_requested(:post, endpoint).with { |req| req.headers["Authorization"].to_s.start_with?("vapid") && req.body.exclude?("Novo papel") })
    expect(inscricao.reload.ultimo_envio_em).to be_present
  end

  it "remove a inscrição que o navegador cancelou" do
    stub_request(:post, endpoint).to_return(status: 410)

    perform_enqueued_jobs { notificar }

    expect(Core::InscricaoPush.where(id: inscricao.id)).to be_empty
  end

  it "mantém a inscrição quando o serviço de push falha" do
    stub_request(:post, endpoint).to_return(status: 500)

    expect { perform_enqueued_jobs { notificar } }.not_to raise_error
    expect(inscricao.reload).to be_present
  end

  it "não envia se a notificação já foi lida" do
    envio = stub_request(:post, endpoint).to_return(status: 201)
    notificacao = notificar
    notificacao.update!(lida_em: Time.current)

    perform_enqueued_jobs

    expect(envio).not_to have_been_requested
  end

  it "não envia quando o push está desligado (sem chaves)" do
    allow(Rails.configuration.x.push).to receive(:ativo).and_return(false)

    expect { notificar }.not_to have_enqueued_job(described_class)
  end
end
