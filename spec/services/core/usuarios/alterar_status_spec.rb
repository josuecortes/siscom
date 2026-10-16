require "rails_helper"

RSpec.describe Core::Usuarios::AlterarStatus do
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:user) { create(:user) }

  it "desativa e derruba as sessões" do
    expect { described_class.call(user: user, ativo: false, alterado_por: admin) }
      .to change { user.reload.versao_sessao }.by(1)

    expect(user).not_to be_ativo
  end

  it "ativa e desbloqueia" do
    user.update!(status: false)
    user.lock_access!

    expect(described_class.call(user: user, ativo: true, alterado_por: admin)).to be_sucesso
    expect(user.reload).to be_ativo
    expect(user).not_to be_access_locked
  end

  it "é idempotente" do
    expect(described_class.call(user: user, ativo: true, alterado_por: admin)).to be_sucesso
  end

  it "recusa quem não tem a permissão" do
    resultado = described_class.call(user: user, ativo: false, alterado_por: create(:user))

    expect(resultado.erros).to eq([ "Você não pode ativar ou desativar usuários." ])
    expect(user.reload).to be_ativo
  end

  it "ninguém desativa a si mesmo" do
    resultado = described_class.call(user: admin, ativo: false, alterado_por: admin)

    expect(resultado.erros).to eq([ "Você não pode desativar o seu próprio usuário." ])
  end

  it "não desativa o último superadministrador ativo" do
    superadmin = create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") }

    resultado = described_class.call(user: superadmin, ativo: false, alterado_por: admin)
    expect(resultado.erros).to eq([ "Não é possível desativar o último superadministrador ativo." ])

    create(:core_concessao, user: create(:user), papel: "superadmin")
    expect(described_class.call(user: superadmin, ativo: false, alterado_por: admin)).to be_sucesso
  end
end
