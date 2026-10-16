require "rails_helper"

RSpec.describe "Limites de requisição (rack-attack)" do
  it "limita tentativas de login para o mesmo e-mail" do
    20.times { post user_session_path, params: { user: { email: "Alvo@seed.ap.gov.br", password: "x" } } }
    expect(response).to have_http_status(:unprocessable_content)

    post user_session_path, params: { user: { email: " alvo@seed.ap.gov.br", password: "x" } }

    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("Muitas tentativas em pouco tempo")
    expect(response.headers["retry-after"]).to eq("600")
  end

  it "não limita e-mails diferentes dentro do teto por IP" do
    25.times { |n| post user_session_path, params: { user: { email: "pessoa#{n}@seed.ap.gov.br", password: "x" } } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "limita o volume de logins por IP" do
    61.times { |n| post user_session_path, params: { user: { email: "pessoa#{n}@seed.ap.gov.br", password: "x" } } }

    expect(response).to have_http_status(:too_many_requests)
  end
end
