require "rails_helper"

RSpec.describe Core::Usuarios::RedefinirSenha do
  let(:user) { create(:user, password: "Senha@Forte123") }
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, papel: "admin_usuarios") } }

  it "gera senha temporária, obriga a troca e derruba as sessões" do
    resultado = nil

    expect { resultado = described_class.call(user: user, redefinido_por: admin) }
      .to change { user.reload.versao_sessao }.by(1)

    expect(resultado).to be_sucesso
    expect(resultado.objeto).to match(/\A\w{12}\z/)
    expect(user.valid_password?(resultado.objeto)).to be(true)
    expect(user.deve_trocar_senha).to be(true)
  end

  it "a senha anterior deixa de valer" do
    described_class.call(user: user, redefinido_por: admin)

    expect(user.reload.valid_password?("Senha@Forte123")).to be(false)
  end

  it "desbloqueia a conta bloqueada por tentativas" do
    user.lock_access!

    described_class.call(user: user, redefinido_por: admin)

    expect(user.reload).not_to be_access_locked
  end

  it "recusa quem não tem a permissão" do
    resultado = described_class.call(user: user, redefinido_por: create(:user))

    expect(resultado.erros).to eq([ "Você não pode redefinir senhas." ])
    expect(described_class.call(user: user)).to be_falha
    expect(user.reload.valid_password?("Senha@Forte123")).to be(true)
  end

  it "pode ser chamado pelo sistema" do
    expect(described_class.call(user: user, pelo_sistema: true)).to be_sucesso
  end
end
