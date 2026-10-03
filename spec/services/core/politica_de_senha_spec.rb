require "rails_helper"

RSpec.describe Core::PoliticaDeSenha do
  it "gera senha temporária de 12 caracteres sem ambíguos" do
    senha = described_class.gerar_temporaria

    expect(senha).to match(/\A[A-HJ-NP-Za-hjkmnp-z2-9]{12}\z/)
    expect(described_class.gerar_temporaria).not_to eq(senha)
  end

  it "reconhece a senha padrão antiga" do
    expect(described_class.padrao_antiga?(" Seed@123 ")).to be(true)
    expect(described_class.padrao_antiga?("Outra@123")).to be(false)
  end
end
