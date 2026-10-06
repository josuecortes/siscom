require "rails_helper"

RSpec.describe "Limite dos arquivos e sessão de formulário" do
  let(:user) { create(:user) }

  describe "todo arquivo enviado tem no máximo 1 MB" do
    before { sign_in user }

    it "recusa a foto de perfil acima do limite e aceita a que cabe" do
      patch meu_perfil_path, params: { user: { avatar: Rack::Test::UploadedFile.new(png_grande, "image/png") } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("deve ter no máximo 1 MB")
      expect(user.reload.avatar).not_to be_attached

      patch meu_perfil_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }
      expect(user.reload.avatar).to be_attached
    end

    it "vale o mesmo limite em todo o sistema (anexo de observação do transporte)" do
      create(:core_concessao, user: user, modulo: "transporte", papel: "tecnico")
      solicitacao = Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Reunião", saida_em: 1.day.from_now, solicitante: user,
                                                    solicitante_nome: user.nome, solicitante_email: user.email)

      resultado = Transporte::Solicitacoes::Observar.call(solicitacao: solicitacao, ator: user, corpo: "Segue o ofício.", anexos: [ Rack::Test::UploadedFile.new(pdf_grande, "application/pdf") ])

      expect([ Anexo::TAMANHO_MAXIMO, resultado.mensagem_de_erro ]).to eq([ 1.megabyte, "Cada anexo pode ter no máximo 1 MB." ])
    end
  end

  describe "pulso da sessão" do
    it "devolve o token de formulário para quem está logado e 401 para quem não está" do
      get pulso_da_sessao_path
      expect(response).to have_http_status(:unauthorized)

      sign_in user
      get pulso_da_sessao_path
      expect(response.parsed_body["token"]).to be_present
      expect(response.headers["Cache-Control"]).to include("no-store")
    end

    it "sessão parada além do limite não é ressuscitada pelo pulso" do
      sign_in user
      get pulso_da_sessao_path
      travel 9.hours

      get pulso_da_sessao_path

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "token de formulário vencido" do
    around do |exemplo|
      ActionController::Base.allow_forgery_protection = true
      exemplo.run
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it "em vez da tela de erro, volta para onde estava com um aviso" do
      sign_in user

      patch meu_perfil_path, params: { authenticity_token: "vencido", user: { avatar: fixture_file_upload("avatar.png", "image/png") } }, headers: { "HTTP_REFERER" => meu_perfil_url }

      expect(response).to redirect_to(meu_perfil_url)
      expect(flash[:alert]).to include("A página ficou aberta por muito tempo")
      expect(user.reload.avatar).not_to be_attached
    end
  end
end
