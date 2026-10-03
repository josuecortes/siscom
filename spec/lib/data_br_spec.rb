require "rails_helper"

RSpec.describe DataBr do
  describe ".interpretar" do
    it "entende dd/mm/aaaa e também o formato do banco" do
      expect(described_class.interpretar("15/01/1985")).to eq(Date.new(1985, 1, 15))
      expect(described_class.interpretar(" 5/3/2001 ")).to eq(Date.new(2001, 3, 5))
      expect(described_class.interpretar("1985-01-15")).to eq(Date.new(1985, 1, 15))
      expect(described_class.interpretar(Time.zone.local(2026, 10, 3, 14))).to eq(Date.new(2026, 10, 3))
    end

    it "nunca troca dia por mês" do
      expect(described_class.interpretar("01/02/1985")).to eq(Date.new(1985, 2, 1))
      expect(described_class.interpretar("13/01/1985")).to eq(Date.new(1985, 1, 13))
    end

    it "devolve nil para data inexistente ou texto fora do formato" do
      [ "31/02/2020", "00/01/2020", "15/13/2020", "1985-15-01", "15-01-1985", "amanhã", "", nil ].each do |valor|
        expect(described_class.interpretar(valor)).to be_nil
      end
    end
  end

  describe ".formatar" do
    it "mostra sempre dd/mm/aaaa, venha a data do banco ou do formulário" do
      expect(described_class.formatar(Date.new(1985, 1, 15))).to eq("15/01/1985")
      expect(described_class.formatar("1985-01-15")).to eq("15/01/1985")
      expect(described_class.formatar("15/01/1985")).to eq("15/01/1985")
    end

    it "devolve o que foi digitado quando não é data, e vazio para nada" do
      expect(described_class.formatar("31/02/2020")).to eq("31/02/2020")
      expect(described_class.formatar(nil)).to eq("")
    end
  end

  describe "em um model (datas_br)" do
    let(:user) { build(:user) }

    it "grava a data digitada em formato brasileiro" do
      user.update!(data_nascimento: "15/01/1985")

      expect(user.reload.data_nascimento).to eq(Date.new(1985, 1, 15))
    end

    it "acusa data inexistente em vez de gravar em branco" do
      user.data_nascimento = "31/02/2020"

      expect(user).not_to be_valid
      expect(user.errors[:data_nascimento]).to eq([ "não é uma data válida (use dd/mm/aaaa)" ])
      expect(user.data_nascimento_before_type_cast).to eq("31/02/2020")
    end

    it "aceita data em branco" do
      user.data_nascimento = ""

      expect(user).to be_valid
    end
  end
end
