require "rails_helper"

RSpec.describe Core::Usuarios::TrocarSenha do
  let(:user) { create(:user, password: "Senha@Forte123", deve_trocar_senha: true) }

  def trocar(**opcoes)
    described_class.call(user: user, senha_atual: "Senha@Forte123", nova_senha: "Nova@Senha456",
                         confirmacao: "Nova@Senha456", **opcoes)
  end

  it "troca a senha e libera a troca obrigatória" do
    expect(trocar).to be_sucesso
    expect(user.reload).to have_attributes(deve_trocar_senha: false)
    expect(user.valid_password?("Nova@Senha456")).to be(true)
  end

  it "recusa senha atual errada sem alterar nada" do
    resultado = trocar(senha_atual: "errada")

    expect(resultado).to be_falha
    expect(user.errors[:current_password]).to eq([ "não confere" ])
    expect(user.reload.valid_password?("Senha@Forte123")).to be(true)
  end

  it "recusa confirmação diferente, senha em branco e senha fora da política" do
    expect(trocar(confirmacao: "Outra@Coisa789")).to be_falha
    expect(trocar(nova_senha: "", confirmacao: "")).to be_falha
    expect(trocar(nova_senha: "Seed@123", confirmacao: "Seed@123").erros.join).to include("senha padrão antiga")
    expect(user.reload.deve_trocar_senha).to be(true)
  end
end
