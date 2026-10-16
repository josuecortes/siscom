require "rails_helper"

RSpec.describe Rh::Importacao::DoLegado do
  let(:sede) { inserir_no_legado(:tipo_unidades, nome: "SEDE") }
  let(:tipo_escola) { inserir_no_legado(:tipo_unidades, nome: "ESCOLA") }
  let(:nuinfo) { inserir_no_legado(:unidades, nome: "Núcleo de Informática", sigla: "nuinfo", tipo_unidade_id: sede) }
  let(:escola) { inserir_no_legado(:unidades, nome: "Escola Estadual A", sigla: "ESCOLA", tipo_unidade_id: tipo_escola) }
  let(:tecnico) { inserir_no_legado(:funcoes, nome: "TECNICO") }

  def usuario_antigo(**atributos)
    create(:user, **atributos).tap do |user|
      user.update_columns(unidade_id: atributos.fetch(:unidade_id, nuinfo), funcao_id: atributos.fetch(:funcao_id, tecnico))
    end
  end

  before do
    nuinfo # a primeira unidade com a sigla fica com ela; a repetida entra sem sigla
    inserir_no_legado(:unidades, nome: "Escola Estadual B", sigla: "ESCOLA", tipo_unidade_id: tipo_escola)
    inserir_no_legado(:unidades, nome: "Outra com sigla repetida", sigla: "NUINFO", tipo_unidade_id: sede)
    inserir_no_legado(:funcoes, nome: " tecnico ")
    inserir_no_legado(:cargos, nome: "Analista")
    escola
  end

  it "importa tipos, unidades, funções e cargos com o id antigo" do
    usuario_antigo
    relatorio = described_class.call

    expect(relatorio).to have_attributes(tipos_unidade: 2, unidades: 4, funcoes: 1, cargos: 1)
    expect(Rh::Unidade.find_by!(legacy_id: nuinfo)).to have_attributes(nome: "NÚCLEO DE INFORMÁTICA", sigla: "NUINFO")
    expect(Rh::Unidade.find_by!(legacy_id: escola)).to have_attributes(sigla: nil, escola?: true)
    expect(Rh::Unidade.where(sigla: "NUINFO").count).to eq(1)
    expect(Rh::Cargo.sole).to have_attributes(nome: "ANALISTA", legacy_id: be_present)
  end

  it "cria a pessoa ligada à conta e a lotação na unidade e função antigas" do
    user = usuario_antigo(nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "529.982.247-25")

    described_class.call

    pessoa = Rh::Pessoa.find_by!(user: user)
    expect(pessoa).to have_attributes(nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br", cpf: "52998224725")
    expect(pessoa.lotacoes.sole).to have_attributes(status: "ativo", lotado_por_nome: "Importação do siscom antigo",
                                                    data_inicio: user.created_at.to_date)
    expect(pessoa.lotacoes.sole.unidade.sigla).to eq("NUINFO")
    expect(pessoa.lotacoes.sole.funcao.nome).to eq("TECNICO")
    expect(Rh::PendenciaImportacao.count).to eq(0)
  end

  it "registra pendências sem deixar de importar" do
    usuario_antigo(nome: "MARIA OLIVEIRA", cpf: "529.982.247-25")
    repetido = usuario_antigo(nome: "JOAO SANTOS", cpf: "52998224725")
    invalido = usuario_antigo(nome: "ANA PAULA", cpf: "123")
    usuario_antigo(nome: "CARLOS LIMA", cpf: nil)
    so_nome = usuario_antigo(nome: "ZEZINHO", cpf: "111.444.777-35")

    relatorio = described_class.call

    expect(relatorio.pessoas).to eq(5)
    expect(relatorio.pendencias).to eq("cpf_repetido" => 1, "cpf_invalido" => 1, "cpf_vazio" => 1, "nome_sem_sobrenome" => 1)
    expect(Rh::Pessoa.find_by!(user: repetido).cpf).to be_nil
    expect(Rh::PendenciaImportacao.find_by!(pessoa: Rh::Pessoa.find_by!(user: invalido))).to have_attributes(descricao: "CPF no cadastro antigo: 123")
    expect(Rh::Pessoa.find_by!(user: so_nome)).to have_attributes(nome: "ZEZINHO", cpf: "11144477735")
  end

  it "é idempotente" do
    usuario_antigo(nome: "MARIA OLIVEIRA", cpf: nil)
    primeiro = described_class.call

    expect(described_class.call).to eq(primeiro)
    expect([ Rh::Pessoa.count, Rh::Lotacao.count, Rh::PendenciaImportacao.count, Rh::Unidade.count ]).to eq([ 1, 1, 1, 4 ])
  end

  it "não importa os usuários padrão de desenvolvimento" do
    create(:user, email: "superadmin@siscom.dev")

    expect(described_class.call.pessoas).to eq(0)
  end
end
