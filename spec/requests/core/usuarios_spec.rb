require "rails_helper"

RSpec.describe "Administração: usuários" do
  let(:admin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:auditor) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "auditor") } }
  let!(:alvo) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  describe "controle de acesso" do
    it "exige login" do
      get core_usuarios_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "nega quem não entra no módulo Core" do
      sign_in create(:user)

      get core_usuarios_path

      expect(response).to have_http_status(:forbidden)
    end

    context "com auditor" do
      before { sign_in auditor }

      it "vê a lista, sem o botão de cadastrar" do
        get core_usuarios_path

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Novo usuário")
      end

      it "não cadastra, edita, redefine senha nem muda status" do
        respostas = [
          -> { get new_core_usuario_path },
          -> { post core_usuarios_path, params: { user: { nome: "X", email: "x@seed.ap.gov.br" } } },
          -> { get edit_core_usuario_path(alvo) },
          -> { patch core_usuario_path(alvo), params: { user: { nome: "OUTRO" } } },
          -> { patch desativar_core_usuario_path(alvo) },
          -> { patch redefinir_senha_core_usuario_path(alvo) }
        ].map { |requisicao| requisicao.call && response.status }

        expect(respostas).to all(eq(403))
        expect(alvo.reload).to have_attributes(nome: "MARIA OLIVEIRA", status: true, deve_trocar_senha: false)
      end
    end
  end

  context "com administrador de usuários" do
    before { sign_in admin }

    it "lista, busca por nome ou e-mail e filtra por status" do
      create(:user, nome: "JOAO INATIVO", status: false)

      get core_usuarios_path
      expect(response.body).to include("MARIA OLIVEIRA", "JOAO INATIVO", "3 usuário(s) cadastrado(s) no sistema")

      get core_usuarios_path, params: { q: "maria@" }
      expect(response.body).to include("MARIA OLIVEIRA", "1 usuário(s) encontrado(s)")
      expect(response.body).not_to include("JOAO INATIVO")

      get core_usuarios_path, params: { status: "inativos" }
      expect(response.body).to include("JOAO INATIVO")
      expect(response.body).not_to include("MARIA OLIVEIRA")
    end

    it "pagina de 20 em 20" do
      create_list(:user, 21)

      get core_usuarios_path
      expect(response.body).to include("Página 1 de 2")

      get core_usuarios_path, params: { page: 2 }
      expect(response.body).to include("Página 2 de 2")
    end

    it "mostra os módulos em que o usuário tem papel" do
      create(:core_concessao, user: alvo, papel: "auditor")

      get core_usuarios_path, params: { q: "maria" }

      expect(response.body).to include("Administração")
    end

    it "cadastra com senha temporária mostrada uma única vez" do
      post core_usuarios_path, params: { user: { nome: "novo servidor", email: "novo@seed.ap.gov.br" } }

      novo = User.find_by!(email: "novo@seed.ap.gov.br")
      senha = response.body[%r{data-senha-temporaria>([^<]+)<}, 1]

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(novo).to have_attributes(nome: "NOVO SERVIDOR", deve_trocar_senha: true, status: true)
      expect(novo.valid_password?(senha)).to be(true)
    end

    it "mostra os erros por campo com 422" do
      post core_usuarios_path, params: { user: { nome: "", email: "maria@seed.ap.gov.br" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Revise os campos destacados", "Nome não pode ficar em branco", "E-mail já está em uso")
    end

    it "edita nome e e-mail" do
      patch core_usuario_path(alvo), params: { user: { nome: "Maria O. Souza", email: "maria.souza@seed.ap.gov.br" } }

      expect(response).to redirect_to(core_usuarios_path)
      expect(alvo.reload).to have_attributes(nome: "MARIA O. SOUZA", email: "maria.souza@seed.ap.gov.br")
    end

    it "responde à edição pelo painel fechando o painel e atualizando a página" do
      patch core_usuario_path(alvo), params: { user: { nome: "MARIA NOVA" } }, as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="update" target="painel"', 'action="refresh"')
      expect(flash[:notice]).to eq("Usuário atualizado com sucesso.")
    end

    it "desativa e reativa" do
      patch desativar_core_usuario_path(alvo)
      expect(response).to redirect_to(core_usuarios_path)
      expect(alvo.reload).not_to be_ativo

      patch ativar_core_usuario_path(alvo)
      expect(alvo.reload).to be_ativo
    end

    it "redefine a senha e mostra a temporária" do
      patch redefinir_senha_core_usuario_path(alvo)

      senha = response.body[%r{data-senha-temporaria>([^<]+)<}, 1]
      expect(alvo.reload.valid_password?(senha)).to be(true)
      expect(alvo.deve_trocar_senha).to be(true)
    end

    it "não deixa agir sobre o próprio usuário" do
      get edit_core_usuario_path(admin)
      expect(response).to have_http_status(:forbidden)
      patch desativar_core_usuario_path(admin)
      expect(response).to have_http_status(:forbidden)
      patch redefinir_senha_core_usuario_path(admin)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
