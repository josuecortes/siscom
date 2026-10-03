require "rails_helper"

RSpec.describe "Administração: acessos e papéis do usuário" do
  let(:superadmin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:auditor) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "auditor") } }
  let(:alvo) { create(:user, nome: "MARIA OLIVEIRA") }

  it "nega quem não tem core.acessos.conceder" do
    sign_in auditor

    respostas = [
      -> { get core_usuario_acessos_path(alvo) },
      -> { post core_usuario_acessos_path(alvo), params: { modulo: "core", papel: "auditor" } },
      -> { patch core_usuario_acessos_path(alvo), params: { modulo: "core", status: "inativo" } }
    ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
    expect(Core::Concessao.where(user: alvo)).to be_empty
  end

  context "com superadministrador" do
    before { sign_in superadmin }

    it "mostra os módulos e os papéis que pode conceder" do
      get core_usuario_acessos_path(alvo)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("MARIA OLIVEIRA", "Administração", "Sem acesso", "Superadministrador", "Auditor")
    end

    it "concede e revoga um papel" do
      post core_usuario_acessos_path(alvo), params: { modulo: "core", papel: "auditor" }
      expect(response.body).to include("Papel concedido.", "Com acesso")
      concessao = Core::Concessao.ativo.find_by!(user: alvo, papel: "auditor")
      expect(concessao.concedido_por).to eq(superadmin)

      delete core_usuario_acessos_path(alvo), params: { concessao_id: concessao.id }
      expect(response.body).to include("Papel revogado.")
      expect(concessao.reload).to be_inativo
    end

    it "bloqueia e libera o módulo" do
      create(:core_concessao, user: alvo, papel: "auditor")

      patch core_usuario_acessos_path(alvo), params: { modulo: "core", status: "inativo" }
      expect(response.body).to include("Módulo bloqueado.", "Bloqueado")
      expect(Core::Autorizacao.new(alvo).acesso?(:core)).to be(false)

      patch core_usuario_acessos_path(alvo), params: { modulo: "core", status: "ativo" }
      expect(response.body).to include("Módulo liberado.")
    end

    it "mostra o erro com 422 quando a regra impede" do
      propria = Core::Concessao.find_by!(user: superadmin, papel: "superadmin")

      delete core_usuario_acessos_path(superadmin), params: { concessao_id: propria.id }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Não é possível revogar o último superadministrador ativo.")
    end

    it "não revoga concessão de outro usuário pelo endereço deste" do
      alheia = create(:core_concessao, user: create(:user), papel: "auditor")

      delete core_usuario_acessos_path(alvo), params: { concessao_id: alheia.id }

      expect(response).to have_http_status(:not_found)
      expect(alheia.reload).to be_ativo
    end
  end

  context "com administrador de usuários" do
    before { sign_in admin }

    it "não oferece nem aceita papéis do Core" do
      get core_usuario_acessos_path(alvo)
      expect(response.body).not_to include("Conceder papel em Administração")

      post core_usuario_acessos_path(alvo), params: { modulo: "core", papel: "superadmin" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Você não pode conceder o papel Superadministrador.")
      expect(Core::Concessao.where(user: alvo)).to be_empty
    end
  end
end
