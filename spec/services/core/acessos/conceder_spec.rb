require "rails_helper"

RSpec.describe Core::Acessos::Conceder do
  let(:user) { create(:user) }
  let(:superadmin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:admin_usuarios) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }

  def conceder(**opcoes)
    described_class.call(user: user, modulo: "core", papel: "auditor", **opcoes)
  end

  it "cria o acesso e a concessão quando o concedente pode" do
    resultado = conceder(concedido_por: superadmin)

    expect(resultado).to be_sucesso
    expect(resultado.objeto).to have_attributes(user: user, modulo: "core", papel: "auditor", concedido_por: superadmin)
    expect(Core::Autorizacao.new(user).pode?("core.auditoria.ver")).to be(true)
  end

  it "é idempotente" do
    primeira = conceder(concedido_por: superadmin).objeto

    expect(conceder(concedido_por: superadmin).objeto).to eq(primeira)
    expect(Core::Concessao.where(user: user).count).to eq(1)
  end

  it "reativa o acesso ao módulo que estava inativo" do
    create(:core_acesso, user: user, modulo: "core", status: "inativo")

    expect(conceder(concedido_por: superadmin)).to be_sucesso
    expect(Core::Acesso.find_by!(user: user, modulo: "core")).to be_ativo
  end

  it "guarda o escopo" do
    resultado = conceder(concedido_por: superadmin, escopo: [ "rh_unidade", 5 ])

    expect(resultado.objeto).to have_attributes(escopo_tipo: "rh_unidade", escopo_id: 5)
  end

  it "recusa quem não pode conceder papéis do Core" do
    expect(conceder(concedido_por: admin_usuarios)).to be_falha
    expect(conceder(concedido_por: create(:user))).to be_falha
    expect(conceder).to be_falha
    expect(Core::Concessao.where(user: user)).to be_empty
  end

  it "permite concessão pelo sistema (importação)" do
    expect(conceder(pelo_sistema: true)).to be_sucesso
  end

  it "recusa papel fora do catálogo e usuário desativado" do
    expect(described_class.call(user: user, modulo: "core", papel: "fantasma", pelo_sistema: true).erros)
      .to eq([ "Papel inexistente no catálogo: core.fantasma." ])

    user.update!(status: false)
    expect(conceder(pelo_sistema: true).erros).to eq([ "Usuário desativado não pode receber papéis." ])
  end

  context "com catálogo de exemplo" do
    include_context "com catálogo de exemplo"

    let(:catalogo_de_exemplo) do
      Dir.mktmpdir do |pasta|
        FileUtils.cp(Rails.root.glob("spec/fixtures/modulos/*.yml") + [ Rails.root.join("config/modulos/core.yml") ], pasta)
        Core::Catalogo.new(pasta)
      end
    end

    it "quem tem core.acessos.conceder concede papéis de outros módulos" do
      resultado = described_class.call(user: user, modulo: "fechado", papel: "leitor", concedido_por: admin_usuarios)

      expect(resultado).to be_sucesso
    end

    it "quem tem papel do módulo concede o que o catálogo do módulo permite" do
      admin_do_modulo = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "fechado", papel: "admin") }
      leitor = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "fechado", papel: "leitor") }

      expect(described_class.call(user: user, modulo: "fechado", papel: "leitor", concedido_por: admin_do_modulo)).to be_sucesso
      expect(described_class.call(user: create(:user), modulo: "fechado", papel: "leitor", concedido_por: leitor)).to be_falha
    end

    it "recusa conceder papel automático" do
      resultado = described_class.call(user: user, modulo: "exemplo", papel: "usuario", pelo_sistema: true)

      expect(resultado.erros).to eq([ "O papel Usuário é automático e não precisa ser concedido." ])
    end
  end
end
