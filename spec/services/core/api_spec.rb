require "rails_helper"

RSpec.describe Core::Api do
  it "lista os módulos do catálogo" do
    expect(described_class.modulos.map(&:chave)).to include("core")
    expect(described_class.modulo(:core).nome).to eq("Administração")
  end
end
