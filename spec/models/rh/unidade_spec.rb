require "rails_helper"

RSpec.describe Rh::Unidade do
  let(:escola) { create(:rh_tipo_unidade, nome: "Escola") }

  it "normaliza nome e sigla em maiúsculas" do
    unidade = create(:rh_unidade, nome: "  assessoria de   comunicação ", sigla: " ascom ")

    expect(unidade).to have_attributes(nome: "ASSESSORIA DE COMUNICAÇÃO", sigla: "ASCOM", sigla_e_nome: "ASCOM - ASSESSORIA DE COMUNICAÇÃO")
  end

  it "exige sigla única, menos para escola, que pode ficar sem" do
    create(:rh_unidade, sigla: "ASCOM")

    expect(build(:rh_unidade, sigla: "ascom")).not_to be_valid
    expect(build(:rh_unidade, sigla: nil)).not_to be_valid
    expect(create(:rh_unidade, sigla: nil, tipo_unidade: escola)).to have_attributes(sigla: nil, sigla_e_nome: /\AUNIDADE/)
    expect(build(:rh_unidade, sigla: "", tipo_unidade: escola)).to be_valid
  end

  describe "árvore" do
    let(:raiz) { create(:rh_unidade, sigla: "SEED") }
    let(:filha) { create(:rh_unidade, sigla: "COGEP", pai: raiz) }
    let(:neta) { create(:rh_unidade, sigla: "NUINFO", pai: filha) }

    it "conhece o caminho desde a raiz e os descendentes" do
      expect(neta.caminho.map(&:sigla)).to eq(%w[SEED COGEP NUINFO])
      expect(raiz.ids_descendentes).to contain_exactly(filha.id, neta.id)
      expect(described_class.raizes).to contain_exactly(raiz)
    end

    it "não deixa a unidade ser pai de si mesma nem criar ciclo" do
      neta

      raiz.pai = raiz
      expect(raiz).not_to be_valid

      raiz.pai = neta
      raiz.validate
      expect(raiz.errors[:pai_id]).to eq([ "não pode ser uma unidade abaixo desta" ])
    end

    it "não apaga unidade com filhas" do
      filha

      expect(raiz.destroy).to be(false)
    end
  end

  it "só aceita dados de escola em unidade do tipo escola" do
    comum = create(:rh_unidade)

    expect(Rh::DadosEscola.new(unidade: comum, nae: "1")).not_to be_valid
    expect(Rh::DadosEscola.new(unidade: create(:rh_unidade, sigla: nil, tipo_unidade: escola), codigo_inep: "16000000")).to be_valid
  end

  it "busca por nome ou sigla" do
    create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
    create(:rh_unidade, nome: "Gabinete", sigla: "GAB")

    expect(described_class.buscar("informát").pluck(:sigla)).to eq([ "NUINFO" ])
    expect(described_class.buscar("gab").pluck(:sigla)).to eq([ "GAB" ])
  end
end
