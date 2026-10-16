require "rails_helper"

RSpec.describe Core::Importacao::Papeis do
  let(:master) { create(:user) }
  let(:admin) { create(:user) }
  let(:comum) { create(:user) }

  before do
    dar_papel_antigo(master, "master")
    dar_papel_antigo(master, "admin")
    dar_papel_antigo(admin, "admin")
    dar_papel_antigo(comum, "user")
  end

  it "converte master em superadmin e admin em admin_usuarios" do
    relatorio = described_class.call(described_class::MAPA_DO_CORE)

    expect(relatorio).to have_attributes(concedidos: 3, ja_existiam: 0, ignorados: [])
    expect(Core::Autorizacao.new(master).papeis(:core)).to contain_exactly("superadmin", "admin_usuarios")
    expect(Core::Autorizacao.new(admin).papeis(:core)).to eq([ "admin_usuarios" ])
    expect(Core::Autorizacao.new(comum).acesso?(:core)).to be(false)
  end

  it "é idempotente" do
    described_class.call(described_class::MAPA_DO_CORE)

    relatorio = described_class.call(described_class::MAPA_DO_CORE)

    expect(relatorio).to have_attributes(concedidos: 0, ja_existiam: 3)
    expect(Core::Concessao.count).to eq(3)
    expect(relatorio.to_s).to eq("0 concedido(s), 3 já existia(m), 0 ignorado(s)")
  end

  it "ignora e relata usuário desativado" do
    admin.update!(status: false)

    relatorio = described_class.call(described_class::MAPA_DO_CORE)

    expect(relatorio.concedidos).to eq(2)
    expect(relatorio.ignorados.sole).to include(admin.email, "admin → core.admin_usuarios", "desativado")
  end
end
