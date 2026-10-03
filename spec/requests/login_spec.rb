require "rails_helper"

RSpec.describe "Login" do
  let!(:user) { create(:user, email: "fulano@seed.ap.gov.br", password: "Senha@Forte123") }

  it "redireciona visitante para o login" do
    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "entra com e-mail e senha corretos" do
    post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "Senha@Forte123" } }

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(root_path)
  end

  it "recusa senha errada com 422" do
    post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "errada" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "recusa usuário desativado" do
    user.update!(status: false)

    post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "Senha@Forte123" } }
    expect(flash[:alert]).to eq(I18n.t("devise.failure.inativo"))

    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "aceita hash bcrypt gerado pelo siscom antigo" do
    hash_antigo = BCrypt::Password.create("Antiga@123", cost: 4).to_s
    user.update_column(:encrypted_password, hash_antigo)

    post user_session_path, params: { user: { email: "fulano@seed.ap.gov.br", password: "Antiga@123" } }

    expect(response).to redirect_to(root_path)
  end

  it "não expõe cadastro público" do
    get "/users/sign_up"

    expect(response).to have_http_status(:not_found)
  end

  it "sai com DELETE" do
    sign_in user

    delete destroy_user_session_path

    expect(response).to have_http_status(:see_other)
  end
end
