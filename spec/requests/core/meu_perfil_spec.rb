require "rails_helper"

RSpec.describe "Minha área: perfil" do
  let(:user) do
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "12345678901", celular: "96991234567",
                  data_nascimento: Date.new(1990, 5, 17))
  end

  it "exige login" do
    get meu_perfil_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "com usuário logado" do
    before { sign_in user }

    it "mostra os dados pessoais formatados" do
      get meu_perfil_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MARIA OLIVEIRA", "maria@seed.ap.gov.br", "123.456.789-01", "(96) 99123-4567", "17/05/1990")
    end

    it "mostra Não informado para dados ausentes" do
      user.update_columns(cpf: nil, celular: nil, data_nascimento: nil)

      get meu_perfil_path

      expect(response.body.scan("Não informado").size).to eq(3) # telefone, CPF e nascimento
    end

    it "troca a imagem do perfil" do
      patch meu_perfil_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }

      expect(response).to redirect_to(meu_perfil_path)
      expect(user.reload.avatar).to be_attached
      follow_redirect!
      expect(response.body).to include("Imagem do perfil atualizada.", 'alt="Avatar do usuário"')
    end

    it "recusa arquivo que não é imagem" do
      patch meu_perfil_path, params: { user: { avatar: fixture_file_upload("documento.txt", "text/plain") } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Imagem deve ser uma imagem PNG, JPG ou WebP")
      expect(user.reload.avatar).not_to be_attached
    end

    it "recusa envio sem arquivo e ignora outros campos" do
      patch meu_perfil_path, params: { user: { nome: "OUTRO NOME", email: "outro@seed.ap.gov.br" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Imagem não foi selecionada")
      expect(user.reload).to have_attributes(nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    end
  end
end
