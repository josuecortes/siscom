require "rails_helper"

# Reorganização dos perfis de um banco que já tinha os perfis da primeira carga (o banco local; em produção a carga já
# nasce com os novos).
RSpec.describe Ti::Importacao::PerfisDeAbertura do
  let(:tipos) do
    [ "REDE", "SISTEMAS WEB", "SISTEMAS WEB (NÃO RESPONSÁVEL)", "CONECTIVIDADE - ESCOLA" ].index_with { |nome| create(:ti_categoria, nome: nome, legacy_id: rand(1000..9999)) }
  end
  let(:escola) { inserir_no_legado(:unidades, nome: "Escola A", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "ESCOLA")) }
  let(:sede) { inserir_no_legado(:unidades, nome: "Núcleo", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "SEDE")) }

  def usuario_antigo(unidade, *papeis) = create(:user).tap { |user| user.update_columns(unidade_id: unidade) && papeis.each { |papel| dar_papel_antigo(user, papel) } }
  def perfis_de(user) = Ti::PerfilUsuario.where(user: user).joins(:perfil_abertura).pluck("ti_perfis_abertura.nome")

  before do
    tipos.each_value { |categoria| create(:ti_problema, categoria: categoria, nome: "DE #{categoria.nome}", legacy_id: rand(1000..9999)) }
    create(:ti_perfil_abertura, nome: "GERAL", padrao: true)
    %w[ESCOLA UNIDADES\ ADMINISTRATIVAS SISTEMAS\ WEB NORMAL].each { |nome| create(:ti_perfil_abertura, nome: nome) }
  end

  it "GERAL vira SERVIDORES, os perfis antigos ficam inativos, o NORMAL vazio sai e cada pessoa vai para o seu perfil" do
    gestora = usuario_antigo(escola, "req_serv_ti", "req_serv_ti_sis")
    servidor = usuario_antigo(sede, "req_serv_ti")

    relatorio = described_class.call

    expect(relatorio).to have_attributes(padrao: "SERVIDORES", inativados: contain_exactly("ESCOLA", "UNIDADES ADMINISTRATIVAS", "SISTEMAS WEB"), apagados: [ "NORMAL" ], pessoas: 2)
    expect(Ti::PerfilAbertura.ativo.order(:nome).pluck(:nome))
      .to eq([ "ADMINISTRATIVO - GESTÃO", "ADMINISTRATIVO - SERVIDORES", "ESCOLAS - GESTÃO ESCOLAR", "ESCOLAS - SERVIDORES", "SERVIDORES" ])
    expect([ perfis_de(gestora), perfis_de(servidor) ]).to eq([ [ "ESCOLAS - GESTÃO ESCOLAR" ], [ "ADMINISTRATIVO - SERVIDORES" ] ])
    expect(Ti::PerfilAbertura.find_by!(nome: "SERVIDORES").problemas.pluck(:nome)).to eq([ "DE SISTEMAS WEB (NÃO RESPONSÁVEL)" ])
  end

  it "rodar de novo não muda nada nem desfaz ajustes feitos nas telas" do
    servidor = usuario_antigo(sede, "req_serv_ti")
    described_class.call
    Ti::PerfilUsuario.where(user: servidor).destroy_all

    relatorio = described_class.call

    expect(relatorio).to have_attributes(criados: [], pessoas: 0, inativados: [], apagados: [])
    expect(perfis_de(servidor)).to be_empty
  end

  it "o NORMAL com alguém dentro não é apagado" do
    Ti::PerfilUsuario.create!(user: create(:user), perfil_abertura: Ti::PerfilAbertura.find_by!(nome: "NORMAL"))

    expect(described_class.call.apagados).to eq([])
  end
end
