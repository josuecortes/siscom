require "rails_helper"

RSpec.describe Ti::Importacao::CatalogoInicial do
  let(:tipos) do
    [ "REDE", "S.O.", "SISTEMAS WEB", "HARDWARE", "SISTEMAS WEB (NÃO RESPONSÁVEL)", "CONECTIVIDADE - ESCOLA", "SUPORTE EXTERNO" ]
      .index_with { |nome| inserir_no_legado(:tipo_problema_tis, nome: nome) }
  end
  let(:sede) { inserir_no_legado(:unidades, nome: "Núcleo de Informática", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "SEDE")) }
  let(:escola) { inserir_no_legado(:unidades, nome: "Escola A", tipo_unidade_id: inserir_no_legado(:tipo_unidades, nome: "ESCOLA")) }

  def problema(tipo, nome, **outros) = inserir_no_legado(:problema_tis, { nome: nome, tipo_problema_ti_id: tipos.fetch(tipo) }.merge(outros))

  def usuario_antigo(unidade, *papeis)
    create(:user).tap do |user|
      user.update_columns(unidade_id: unidade)
      papeis.each { |papel| dar_papel_antigo(user, papel) }
    end
  end

  def abre(user) = Ti::Problema.que_pode_abrir(user).joins(:categoria).pluck("ti_categorias.nome").uniq.sort

  before do
    problema("REDE", "PROBLEMAS ACESSO INTERNET")
    problema("S.O.", "INSTALACAO DE SOFTWARE")
    problema("S.O.", " INSTALACAO DE SOFTWARE\t")
    problema("S.O.", "VIRUS NO COMPUTADOR", status: false)
    problema("SISTEMAS WEB", "PRODOC - CADASTRO")
    problema("SISTEMAS WEB", "GOOGLE DRIVE - Permissão de Acesso")
    problema("HARDWARE", "COMPUTADOR NAO LIGA")
    problema("SISTEMAS WEB (NÃO RESPONSÁVEL)", "PRODOC - PROBLEMAS")
    problema("CONECTIVIDADE - ESCOLA", "PROBLEMA COM INTERNET")
    problema("SUPORTE EXTERNO", "SUPORTE PRODAP")
  end

  it "traz os tipos como categorias e os problemas como solicitações, com o id antigo" do
    relatorio = described_class.call

    expect(relatorio).to have_attributes(categorias: 8, solicitacoes: 11)
    expect(Ti::Categoria.where.not(legacy_id: nil).pluck(:nome)).to match_array(tipos.keys)
    expect(Ti::Problema.joins(:categoria).where(ti_categorias: { nome: "S.O." }).order(:id).pluck(:nome, :status))
      .to eq([ [ "INSTALACAO DE SOFTWARE", "ativo" ], [ "INSTALACAO DE SOFTWARE (2)", "ativo" ], [ "VIRUS NO COMPUTADOR", "inativo" ] ])
  end

  it "marca vários chamados abertos só nos tipos de sistemas web, e nenhuma importada exige triagem" do
    described_class.call

    expect(Ti::Problema.where(permite_varios_abertos: true).pluck(:nome))
      .to contain_exactly("PRODOC - CADASTRO", "GOOGLE DRIVE - PERMISSÃO DE ACESSO", "PRODOC - PROBLEMAS", "SOLICITAÇÃO GERAL")
    expect(Ti::Problema.where(exige_triagem: true).pluck(:nome)).to eq([ "SOLICITAÇÃO GERAL" ])
  end

  it "recria os formulários especiais como campos e põe Observações em todas" do
    described_class.call
    campos = ->(nome) { Ti::Problema.find_by!(nome: nome).campos.ordenados }

    expect(campos.call("PRODOC - CADASTRO").pluck(:rotulo)).to eq(
      [ "Nome completo", "E-mail", "CPF", "RG", "Data de nascimento", "Celular", "Cargo", "Função", "Estado", "Município", "Perfil",
        "Unidade/pasta de destino", "Carta de apresentação ou decreto de nomeação", "Observações" ]
    )
    expect(campos.call("PRODOC - CADASTRO").find_by!(rotulo: "Cargo")).to have_attributes(tipo: "busca", fonte: "rh_cargos", obrigatorio: true)
    expect(campos.call("GOOGLE DRIVE - PERMISSÃO DE ACESSO").find_by!(tipo: "selecao").opcoes.size).to eq(3)
    expect(campos.call("PRODOC - PROBLEMAS").pluck(:rotulo, :obrigatorio)).to eq([ [ "Observações", true ] ])
    expect(campos.call("COMPUTADOR NAO LIGA").pluck(:rotulo, :obrigatorio)).to eq([ [ "Observações", false ] ])
  end

  it "cria o perfil GERAL padrão com a solicitação descritiva" do
    described_class.call

    geral = Ti::PerfilAbertura.find_by!(nome: "GERAL")
    expect(geral).to have_attributes(padrao: true)
    expect(geral.problemas.sole).to have_attributes(nome: "SOLICITAÇÃO GERAL", exige_triagem: true)
    expect(geral.problemas.sole.campos.ordenados.pluck(:tipo, :obrigatorio)).to eq([ [ "texto_longo", true ], [ "arquivos", false ] ])
  end

  it "reproduz quem abria o quê no siscom antigo com os perfis de abertura" do
    sede_comum = usuario_antigo(sede, "req_serv_ti")
    sede_sistemas = usuario_antigo(sede, "req_serv_ti", "req_serv_ti_sis")
    escola_comum = usuario_antigo(escola, "req_serv_ti")
    escola_sistemas = usuario_antigo(escola, "req_serv_ti", "req_serv_ti_sis")
    sem_permissao = usuario_antigo(sede)

    described_class.call

    expect(abre(sede_comum)).to eq([ "HARDWARE", "OUTROS", "REDE", "S.O.", "SISTEMAS WEB (NÃO RESPONSÁVEL)", "SUPORTE EXTERNO" ])
    expect(abre(sede_sistemas)).to eq(abre(sede_comum).push("SISTEMAS WEB").sort)
    expect(abre(escola_comum)).to eq([ "CONECTIVIDADE - ESCOLA", "OUTROS", "SISTEMAS WEB (NÃO RESPONSÁVEL)" ])
    expect(abre(escola_sistemas)).to eq([ "CONECTIVIDADE - ESCOLA", "OUTROS", "SISTEMAS WEB", "SISTEMAS WEB (NÃO RESPONSÁVEL)" ])
    expect(abre(sem_permissao)).to eq([ "OUTROS" ])
  end

  it "dá o papel de técnico e monta o grupo SUPORTE TI, que atende tudo" do
    tecnico = usuario_antigo(sede, "tec_serv_ti")

    relatorio = described_class.call

    grupo = Ti::GrupoTecnico.find_by!(nome: "SUPORTE TI")
    expect(relatorio.tecnicos).to eq(1)
    expect(grupo.membros).to contain_exactly(tecnico)
    expect(grupo.problemas.count).to eq(Ti::Problema.count)
    expect(Core::Autorizacao.new(tecnico).papeis(:ti)).to include("tecnico")
  end

  it "rodar de novo não duplica nem desfaz ajustes feitos nas telas" do
    maria = usuario_antigo(sede, "req_serv_ti")
    described_class.call
    Ti::PerfilUsuario.where(user: maria).destroy_all
    Ti::Problema.find_by!(nome: "PROBLEMAS ACESSO INTERNET").update!(nome: "SEM INTERNET")
    contagem = -> { [ Ti::Categoria, Ti::Problema, Ti::CampoProblema, Ti::PerfilAbertura, Ti::ProblemaPerfil, Ti::ProblemaGrupo ].map(&:count) }
    antes = contagem.call

    described_class.call

    expect(contagem.call).to eq(antes)
    expect(Ti::PerfilUsuario.where(user: maria)).to be_empty
    expect(Ti::Problema.where(nome: "PROBLEMAS ACESSO INTERNET")).to be_empty
  end
end
