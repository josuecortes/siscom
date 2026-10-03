require "rails_helper"

RSpec.describe FormatosHelper do
  it "formata CPF de 11 dígitos e devolve o original nos outros casos" do
    expect(helper.formatar_cpf("12345678901")).to eq("123.456.789-01")
    expect(helper.formatar_cpf("123.456.789-01")).to eq("123.456.789-01")
    expect(helper.formatar_cpf("123")).to eq("123")
    expect(helper.formatar_cpf(nil)).to be_nil
  end

  it "formata telefone com 10 ou 11 dígitos" do
    expect(helper.formatar_telefone("96991234567")).to eq("(96) 99123-4567")
    expect(helper.formatar_telefone("(96) 3212-3456")).to eq("(96) 3212-3456")
    expect(helper.formatar_telefone("3212")).to eq("3212")
    expect(helper.formatar_telefone("")).to be_nil
  end
end
