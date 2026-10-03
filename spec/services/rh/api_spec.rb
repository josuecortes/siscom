require "rails_helper"

RSpec.describe Rh::Api do
  let(:user) { create(:user) }
  let(:pessoa) { create(:rh_pessoa, user: user) }
  let(:nuinfo) { create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO") }
  let(:gabinete) { create(:rh_unidade, nome: "Gabinete", sigla: "GAB") }

  it "devolve as lotações ativas da conta, a mais recente primeiro" do
    create(:rh_lotacao, pessoa: pessoa, unidade: gabinete, funcao: create(:rh_funcao, nome: "Assessor"), data_inicio: 2.years.ago.to_date)
    create(:rh_lotacao, pessoa: pessoa, unidade: nuinfo, funcao: create(:rh_funcao, nome: "Técnico"), data_inicio: Date.current)
    create(:rh_lotacao, pessoa: pessoa, status: "inativo", data_fim: Date.current)

    lotacoes = described_class.lotacoes_ativas(user)

    expect(lotacoes.map { |l| [ l.unidade.sigla, l.funcao ] }).to eq([ [ "NUINFO", "TÉCNICO" ], [ "GAB", "ASSESSOR" ] ])
    expect(described_class.unidade_atual(user)).to have_attributes(id: nuinfo.id, sigla_e_nome: "NUINFO - NÚCLEO DE INFORMÁTICA")
    expect(described_class.lotacao_atual(user).data_inicio).to eq(Date.current)
  end

  it "devolve vazio para conta sem pessoa ou sem lotação" do
    expect(described_class.lotacoes_ativas(user)).to eq([])
    expect(described_class.unidade_atual(nil)).to be_nil
  end

  it "busca unidades ativas e encontra uma por id, como dados simples" do
    nuinfo
    create(:rh_unidade, nome: "Núcleo Inativo", sigla: "NI", status: "inativo")

    expect(described_class.buscar_unidades("núcleo").map(&:sigla)).to eq([ "NUINFO" ])
    expect(described_class.unidade(nuinfo.id)).to be_a(described_class::Unidade)
    expect(described_class.unidade(0)).to be_nil
  end

  it "lista as contas com lotação ativa na unidade" do
    create(:rh_lotacao, pessoa: pessoa, unidade: nuinfo)
    create(:rh_lotacao, pessoa: create(:rh_pessoa, user: nil), unidade: nuinfo)
    create(:rh_lotacao, pessoa: create(:rh_pessoa, user: create(:user)), unidade: gabinete)

    expect(described_class.ids_dos_usuarios_da_unidade(nuinfo.id)).to eq([ user.id ])
  end

  it "publica entidades com registros e campos existentes" do
    described_class.entidades_publicaveis.each do |entidade, definicao|
      colunas = described_class.registros_da_entidade(entidade).klass.column_names

      expect(definicao[:campos] - colunas).to be_empty
      expect(definicao[:campos]).to include(*definicao[:campos_busca], definicao[:campo_rotulo], definicao[:campo_valor])
    end
    expect { described_class.registros_da_entidade("nada") }.to raise_error(ArgumentError)
  end
end
