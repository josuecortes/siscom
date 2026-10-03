require "rails_helper"

RSpec.describe Core::Acessos::AlterarModulo do
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }
  let(:user) { create(:user) }

  it "bloqueia e libera o módulo para o usuário" do
    create(:core_concessao, user: user, papel: "auditor")

    expect(described_class.call(user: user, modulo: "core", ativo: false, alterado_por: admin)).to be_sucesso
    expect(Core::Autorizacao.new(user).acesso?(:core)).to be(false)

    expect(described_class.call(user: user, modulo: "core", ativo: true, alterado_por: admin)).to be_sucesso
    expect(Core::Autorizacao.new(user).acesso?(:core)).to be(true)
  end

  it "cria o registro de acesso quando ainda não existe" do
    resultado = described_class.call(user: user, modulo: "core", ativo: false, alterado_por: admin)

    expect(resultado.objeto).to have_attributes(user: user, modulo: "core", status: "inativo")
  end

  it "recusa módulo inexistente e quem não tem a permissão" do
    expect(described_class.call(user: user, modulo: "nada", ativo: false, alterado_por: admin).erros)
      .to eq([ "Módulo inexistente no catálogo: nada." ])
    expect(described_class.call(user: user, modulo: "core", ativo: false, alterado_por: create(:user)).erros)
      .to eq([ "Você não pode alterar acessos." ])
  end

  it "ninguém bloqueia o próprio acesso à Administração" do
    resultado = described_class.call(user: admin, modulo: "core", ativo: false, alterado_por: admin)

    expect(resultado.erros).to eq([ "Você não pode bloquear o seu próprio acesso à Administração." ])
  end

  it "não bloqueia o último superadministrador ativo" do
    superadmin = create(:user).tap { |u| create(:core_concessao, user: u, papel: "superadmin") }

    resultado = described_class.call(user: superadmin, modulo: "core", ativo: false, alterado_por: admin)

    expect(resultado.erros).to eq([ "Não é possível bloquear o último superadministrador ativo." ])
  end
end
