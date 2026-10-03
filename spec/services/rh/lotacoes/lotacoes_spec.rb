require "rails_helper"

RSpec.describe Rh::Lotacoes do # rubocop:disable RSpec/SpecFilePathFormat
  let(:operador) { create(:user, nome: "OPERADOR DO RH", email: "operador@seed.ap.gov.br").tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "operador") } }
  let(:pessoa) { create(:rh_pessoa) }
  let(:unidade) { create(:rh_unidade, sigla: "NUINFO", nome: "Núcleo de Informática") }
  let(:funcao) { create(:rh_funcao, nome: "Técnico") }

  def lotar(**extras)
    Rh::Lotacoes::Lotar.call(pessoa: pessoa, atributos: { unidade_id: unidade.id, funcao_id: funcao.id }.merge(extras), lotado_por: operador)
  end

  it "lota a pessoa com data de hoje por padrão e guarda quem lotou" do
    lotacao = lotar.objeto

    expect(lotacao).to have_attributes(status: "ativo", data_inicio: Date.current, lotado_por_nome: "OPERADOR DO RH", lotado_por_email: "operador@seed.ap.gov.br")
    expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "lotacao.criada", alvo_id: pessoa.id,
                                                                      dados: { "unidade" => "NUINFO - NÚCLEO DE INFORMÁTICA", "funcao" => "TÉCNICO" })
  end

  it "aceita a data em formato brasileiro e recusa lotação repetida, unidade ou função inativa" do
    expect(lotar(data_inicio: "01/03/2024").objeto.data_inicio).to eq(Date.new(2024, 3, 1))
    expect(lotar).to be_falha

    unidade.update!(status: "inativo")
    expect(lotar(funcao_id: create(:rh_funcao).id).objeto.errors[:unidade_id]).to eq([ "está inativa" ])
  end

  it "encerra fechando a data de fim e guardando quem encerrou; é idempotente" do
    lotacao = lotar(data_inicio: "01/03/2024").objeto

    2.times { expect(Rh::Lotacoes::Encerrar.call(lotacao: lotacao, encerrado_por: operador)).to be_sucesso }

    expect(lotacao.reload).to have_attributes(status: "inativo", data_fim: Date.current, encerrado_por_nome: "OPERADOR DO RH")
    expect(Core::RegistroAuditoria.where(evento: "lotacao.encerrada").count).to eq(1)
    expect(lotar).to be_sucesso
  end

  it "leitor não lota nem encerra" do
    leitor = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "rh", papel: "leitor") }
    lotacao = lotar.objeto

    expect(Rh::Lotacoes::Lotar.call(pessoa: create(:rh_pessoa), atributos: { unidade_id: unidade.id, funcao_id: funcao.id }, lotado_por: leitor)).to be_falha
    expect(Rh::Lotacoes::Encerrar.call(lotacao: lotacao, encerrado_por: leitor)).to be_falha
    expect(lotacao.reload).to be_ativo
  end
end
