require "rails_helper"

RSpec.describe Rh::Lotacao do
  let(:lotacao) { create(:rh_lotacao) }

  it "permite várias lotações da mesma pessoa, mas só uma ativa por unidade e função" do
    repetida = build(:rh_lotacao, pessoa: lotacao.pessoa, unidade: lotacao.unidade, funcao: lotacao.funcao)

    expect(repetida).not_to be_valid
    expect(build(:rh_lotacao, pessoa: lotacao.pessoa, unidade: lotacao.unidade)).to be_valid
    expect(build(:rh_lotacao, pessoa: lotacao.pessoa, funcao: lotacao.funcao)).to be_valid
  end

  it "aceita lotar de novo depois de encerrar" do
    lotacao.update!(status: "inativo", data_fim: Date.current)

    expect(build(:rh_lotacao, pessoa: lotacao.pessoa, unidade: lotacao.unidade, funcao: lotacao.funcao)).to be_valid
  end

  it "não aceita fim antes do início" do
    lotacao.data_fim = lotacao.data_inicio - 1

    expect(lotacao).not_to be_valid
  end

  it "o banco também barra duas ativas iguais" do
    copia = lotacao.dup

    expect { copia.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe "tabelas de referência" do
    it "têm nome único em maiúsculas e não são apagadas em uso" do
      expect(create(:rh_funcao, nome: " chefe  de núcleo ").nome).to eq("CHEFE DE NÚCLEO")
      expect(build(:rh_funcao, nome: "Chefe de Núcleo")).not_to be_valid
      expect(lotacao.funcao.destroy).to be(false)
      expect(lotacao.unidade.tipo_unidade.destroy).to be(false)
    end
  end
end
