require "rails_helper"

RSpec.describe "TI: abrir chamado em nome de outra pessoa" do
  let(:tecnico) { create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }
  let(:geral) { create(:ti_perfil_abertura, nome: "Geral", padrao: true) }
  let(:internet) { create(:ti_problema, nome: "Sem internet").tap { |p| p.perfis_abertura << geral } }

  def solicitacao_do_perfil(nome, perfil) = create(:ti_problema, nome: nome).tap { |problema| problema.perfis_abertura << create(:ti_perfil_abertura, nome: perfil) }

  def abrir(solicitacao, pessoa: maria, campos: {}, **chamado)
    post ti_chamado_para_outro_path, params: { chamado: { solicitante_id: pessoa&.id, problema_id: solicitacao.id }.merge(chamado), campos: campos }
  end

  before { Rh::Tabelas.garantir_padroes }

  it "usuário comum não abre em nome de outra pessoa nem procura usuários" do
    sign_in maria

    respostas = [ -> { get new_ti_chamado_para_outro_path }, -> { abrir(internet, pessoa: tecnico) }, -> { get ti_opcoes_de_usuarios_path } ]
                .map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
    expect(Ti::Chamado.count).to eq(0)
  end

  context "com técnico" do
    before { sign_in tecnico }

    it "o chamado fica em nome da pessoa, com o registro de quem abriu, e ela é avisada" do
      abrir(internet)

      chamado = Ti::Chamado.sole
      expect(response).to redirect_to(ti_chamado_path(chamado))
      expect(chamado).to have_attributes(solicitante: maria, solicitante_nome: "MARIA OLIVEIRA", aberto_por: tecnico)
      expect(chamado.eventos.sole).to have_attributes(ator: tecnico, nota: "Chamado aberto por JOAO TECNICO em nome de MARIA OLIVEIRA.")
      expect(maria.notificacoes.sole).to have_attributes(titulo: "Chamado aberto em seu nome")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "chamado.aberto", ator: tecnico, dados: include("em_nome_de" => maria.id))
    end

    it "a pessoa vê o chamado em Meus chamados; quem abriu também consegue abrir a página dele" do
      abrir(internet)
      chamado = Ti::Chamado.sole

      get ti_chamado_path(chamado)
      expect(response.body).to include("Aberto por", "JOAO TECNICO (em nome do solicitante)")
      get ti_chamados_path
      expect(response.body).to include("0 chamado(s) em abertos")

      sign_in maria
      get ti_chamados_path
      expect(response.body).to include("1 chamado(s) em abertos", chamado.codigo)
    end

    it "valem os perfis de abertura da pessoa escolhida, não os de quem abre" do
      conectividade = solicitacao_do_perfil("Conectividade da escola", "Escola")
      sistemas = solicitacao_do_perfil("Prodoc - Cadastro", "Sistemas")
      Ti::PerfilUsuario.create!(user: maria, perfil_abertura: conectividade.perfis_abertura.sole)
      Ti::PerfilUsuario.create!(user: tecnico, perfil_abertura: sistemas.perfis_abertura.sole)
      internet

      get new_ti_chamado_para_outro_path, params: { chamado: { solicitante_id: maria.id } }
      expect(response.body).to include("Abrir chamado para outra pessoa", "CONECTIVIDADE DA ESCOLA", "SEM INTERNET")
      expect(response.body).not_to include("PRODOC - CADASTRO")

      abrir(sistemas)
      expect(response.body).to include("Solicitação deve ser escolhida na lista")
      abrir(conectividade)
      expect(Ti::Chamado.sole.problema).to eq(conectividade)
    end

    it "usa a lotação da pessoa e respeita o limite de chamados dela" do
      nuinfo = create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
      pessoa = create(:rh_pessoa, user: maria, email: maria.email, nome: maria.nome)
      create(:rh_lotacao, pessoa: pessoa, unidade: nuinfo, funcao: create(:rh_funcao, nome: "Técnico"))

      abrir(internet)
      abrir(internet)

      expect(Ti::Chamado.sole).to have_attributes(rh_unidade_id: nuinfo.id, unidade_nome: "NUINFO - NÚCLEO DE INFORMÁTICA")
      expect(response.body).to include("MARIA OLIVEIRA já tem um chamado em andamento para esta solicitação.")
    end

    it "exige escolher uma pessoa ativa, que não seja quem está abrindo" do
      inativa = create(:user, status: false)

      [ nil, inativa, tecnico ].each { |pessoa| abrir(internet, pessoa: pessoa) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Pessoa deve ser escolhido na lista")
      expect(Ti::Chamado.count).to eq(0)
    end

    it "procura usuários ativos por nome ou e-mail, sem quem está abrindo" do
      maria
      create(:user, nome: "MARIANA INATIVA", status: false)

      get ti_opcoes_de_usuarios_path, params: { q: "mari" }
      expect(response.parsed_body).to include("todas" => false, "opcoes" => [ { "valor" => maria.id, "rotulo" => "MARIA OLIVEIRA", "subtitulo" => "maria@seed.ap.gov.br" } ])

      get ti_opcoes_de_usuarios_path
      expect(response.parsed_body["opcoes"].pluck("rotulo")).to eq([ "MARIA OLIVEIRA" ])
    end
  end
end
