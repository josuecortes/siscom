require "rails_helper"

RSpec.describe "Avisos push do aparelho" do
  let(:maria) { create(:user) }
  let(:inscricao) { { endpoint: "https://push.exemplo.test/abc", keys: { p256dh: "chave-publica", auth: "segredo" } } }

  it "exige login" do
    post inscricao_push_path, params: { inscricao: inscricao }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end

  context "com usuário logado" do
    before { sign_in maria }

    it "guarda a inscrição do aparelho e não duplica" do
      2.times { post inscricao_push_path, params: { inscricao: inscricao }, as: :json }

      expect(response).to have_http_status(:created)
      expect(maria.inscricoes_push.sole).to have_attributes(endpoint: "https://push.exemplo.test/abc", p256dh: "chave-publica", auth: "segredo")
    end

    it "passa a inscrição para quem entrou por último no mesmo aparelho" do
      create(:user).inscricoes_push.create!(endpoint: inscricao[:endpoint], p256dh: "x", auth: "y")

      post inscricao_push_path, params: { inscricao: inscricao }, as: :json

      expect(Core::InscricaoPush.sole.user).to eq(maria)
    end

    it "recusa endereço sem https ou que não é de um serviço de push conhecido" do
      recusados = [ "http://push.exemplo.test/x", "https://interno.seed.ap.gov.br/x", "https://push.exemplo.test.golpe.com/x",
                    "https://127.0.0.1/x", "nada" ].map do |endpoint|
        post inscricao_push_path, params: { inscricao: inscricao.merge(endpoint: endpoint) }, as: :json
        response.status
      end

      expect(recusados).to all(eq(422))
      expect(Core::InscricaoPush.count).to eq(0)
    end

    it "aceita os serviços de push dos navegadores" do
      [ "https://fcm.googleapis.com/fcm/send/abc", "https://updates.push.services.mozilla.com/wpush/v2/abc",
        "https://web.push.apple.com/abc" ].each do |endpoint|
        post inscricao_push_path, params: { inscricao: inscricao.merge(endpoint: endpoint) }, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    it "remove só a inscrição do próprio usuário" do
      maria.inscricoes_push.create!(endpoint: inscricao[:endpoint], p256dh: "x", auth: "y")
      alheia = create(:user).inscricoes_push.create!(endpoint: "https://push.exemplo.test/outra", p256dh: "x", auth: "y")

      delete inscricao_push_path, params: { endpoint: inscricao[:endpoint] }, as: :json
      delete inscricao_push_path, params: { endpoint: alheia.endpoint }, as: :json

      expect(response).to have_http_status(:no_content)
      expect(Core::InscricaoPush.all).to contain_exactly(alheia)
    end

    it "mostra o cartão de avisos na tela de notificações" do
      get notificacoes_path

      expect(response.body).to include("Avisos neste aparelho", "Ativar avisos neste aparelho", Core::Notificacoes::Push.chave_publica)
    end
  end
end
