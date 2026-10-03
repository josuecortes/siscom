require "rails_helper"

RSpec.describe User, "política de senha" do
  let(:user) { create(:user, password: "Senha@Forte123") }

  def trocar(senha)
    user.update(password: senha, password_confirmation: senha)
  end

  it "exige pelo menos 8 caracteres" do
    expect(trocar("Abc@123")).to be(false)
    expect(user.errors[:password].first).to include("8 caracteres")
  end

  it "recusa a senha padrão antiga do siscom" do
    expect(trocar("Seed@123")).to be(false)
    expect(trocar("seed@123")).to be(false)
    expect(user.errors[:password]).to include("não pode ser a senha padrão antiga")
  end

  it "recusa repetir a senha atual" do
    expect(trocar("Senha@Forte123")).to be(false)
    expect(user.errors[:password]).to include("não pode repetir uma das últimas 5 senhas")
  end

  it "recusa as últimas 5 senhas e libera a sexta mais antiga" do
    senhas = (1..5).map { |n| "Outra@Senha#{n}" }
    senhas.each { |senha| expect(trocar(senha)).to be(true) }

    expect(trocar("Outra@Senha1")).to be(false)
    expect(trocar("Senha@Forte123")).to be(true)
    expect(user.senhas_anteriores.count).to eq(5)
  end

  it "registra quando a senha foi alterada" do
    freeze_time do
      trocar("Outra@Senha1")

      expect(user.reload.senha_alterada_em).to eq(Time.current)
    end
  end

  it "trocar a senha derruba as sessões abertas" do
    expect { trocar("Outra@Senha1") }.to(change(user, :authenticatable_salt))
  end

  it "não mexe em hash antigo quando outros dados mudam" do
    user.update_column(:encrypted_password, BCrypt::Password.create("Seed@123", cost: 4).to_s)

    expect(user.reload.update(nome: "NOVO NOME")).to be(true)
    expect(user.senhas_anteriores).to be_empty
  end

  describe Core::PoliticaDeSenha do
    it "gera senha temporária de 12 caracteres sem ambíguos" do
      senha = described_class.gerar_temporaria

      expect(senha).to match(/\A[A-HJ-NP-Za-hjkmnp-z2-9]{12}\z/)
      expect(described_class.gerar_temporaria).not_to eq(senha)
    end
  end
end
