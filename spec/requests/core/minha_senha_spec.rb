require "rails_helper"

RSpec.describe "Minha área: trocar senha" do
  let(:user) { create(:user, email: "fulano@seed.ap.gov.br", password: "Senha@Forte123") }

  def enviar(**campos)
    padrao = { current_password: "Senha@Forte123", password: "Nova@Senha456", password_confirmation: "Nova@Senha456" }
    patch minha_senha_path, params: { user: padrao.merge(campos) }
  end

  it "exige login" do
    get edit_minha_senha_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "com usuário logado" do
    before { sign_in user }

    it "mostra o formulário" do
      get edit_minha_senha_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Atualizar senha")
    end

    it "troca a senha, mantém a sessão atual e volta ao início" do
      enviar

      expect(response).to redirect_to(root_path)
      expect(response).to have_http_status(:see_other)
      get root_path
      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("Nova@Senha456")).to be(true)
    end

    it "mostra o erro no campo com 422" do
      enviar(current_password: "errada")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Senha atual não confere")
    end

    it "continua logado depois de um erro na senha nova" do
      enviar(password: "Seed@123", password_confirmation: "Seed@123")
      expect(response).to have_http_status(:unprocessable_content)

      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "troca obrigatória" do
    before do
      user.update!(deve_trocar_senha: true)
      sign_in user
    end

    it "leva qualquer página para a tela de troca" do
      get root_path

      expect(response).to redirect_to(edit_minha_senha_path)
      follow_redirect!
      expect(response.body).to include("Sua senha precisa ser alterada para continuar usando o SISCOM.")
    end

    it "libera o sistema depois da troca e ainda permite sair" do
      enviar
      get root_path
      expect(response).to have_http_status(:ok)

      delete destroy_user_session_path
      expect(response).to have_http_status(:see_other)
    end
  end

  describe "senha padrão antiga do siscom" do
    it "quem entra com Seed@123 fica obrigado a trocar" do
      user.update_column(:encrypted_password, BCrypt::Password.create("Seed@123", cost: 4).to_s)

      post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "Seed@123" } }

      expect(user.reload.deve_trocar_senha).to be(true)
      get root_path
      expect(response).to redirect_to(edit_minha_senha_path)
    end

    it "quem entra com outra senha não é afetado" do
      post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "Senha@Forte123" } }

      expect(user.reload.deve_trocar_senha).to be(false)
    end
  end

  it "não tem recuperação de senha por e-mail" do
    get "/users/password/new"

    expect(response).to have_http_status(:not_found)
  end
end
