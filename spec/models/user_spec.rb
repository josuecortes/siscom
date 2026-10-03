require "rails_helper"

RSpec.describe User do
  describe "#active_for_authentication?" do
    it "permite usuário ativo" do
      expect(build(:user, status: true)).to be_active_for_authentication
    end

    it "bloqueia usuário desativado" do
      user = build(:user, status: false)

      expect(user).not_to be_active_for_authentication
      expect(user.inactive_message).to eq(:inativo)
    end
  end

  it "não tem cadastro público (:registerable)" do
    expect(described_class.devise_modules).not_to include(:registerable)
  end

  describe "política de senha" do
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
  end
end
