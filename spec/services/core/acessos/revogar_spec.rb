require "rails_helper"

RSpec.describe Core::Acessos::Revogar do
  let(:superadmin) { create(:user) }
  let!(:concessao_superadmin) { create(:core_concessao, user: superadmin, papel: "superadmin") }
  let(:concessao) { create(:core_concessao, papel: "auditor") }

  it "inativa a concessão e tira a permissão" do
    resultado = described_class.call(concessao: concessao, revogado_por: superadmin)

    expect(resultado).to be_sucesso
    expect(concessao.reload).to be_inativo
    expect(Core::Autorizacao.new(concessao.user).pode?("core.auditoria.ver")).to be(false)
  end

  it "é idempotente para concessão já revogada" do
    concessao.inativo!

    expect(described_class.call(concessao: concessao)).to be_sucesso
  end

  it "recusa quem não pode conceder aquele papel" do
    resultado = described_class.call(concessao: concessao, revogado_por: create(:user))

    expect(resultado.erros).to eq([ "Você não pode revogar esta permissão." ])
    expect(concessao.reload).to be_ativo
  end

  it "não revoga o último superadministrador ativo" do
    resultado = described_class.call(concessao: concessao_superadmin, revogado_por: superadmin)

    expect(resultado.erros).to eq([ "Não é possível revogar o último superadministrador ativo." ])
    expect(concessao_superadmin.reload).to be_ativo
  end

  it "não conta superadministrador desativado como reserva" do
    create(:core_concessao, user: create(:user, status: false), papel: "superadmin")

    expect(described_class.call(concessao: concessao_superadmin, pelo_sistema: true)).to be_falha
  end

  it "revoga um superadministrador quando existe outro ativo" do
    create(:core_concessao, user: create(:user), papel: "superadmin")

    expect(described_class.call(concessao: concessao_superadmin, revogado_por: superadmin)).to be_sucesso
  end
end
