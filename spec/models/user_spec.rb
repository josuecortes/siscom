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
end
