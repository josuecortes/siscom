require "rails_helper"

RSpec.describe "TI: permissões" do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }
  let(:tecnico) { create(:user, nome: "TECNICO DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") } }
  let!(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  def concedidos = Core::Api.papeis_concedidos([ maria.id ], modulo: :ti).fetch(maria.id, [])

  it "todo usuário é solicitante: pode abrir chamados, mas não triar nem atender" do
    autorizacao = Core::Autorizacao.new(maria)

    expect(autorizacao.papeis(:ti)).to eq([ "solicitante" ])
    expect(autorizacao.pode?("ti.chamados.abrir")).to be(true)
    expect(%w[ti.chamados.triar ti.chamados.atender ti.catalogo.gerenciar].map { |p| autorizacao.pode?(p) }).to all(be(false))
  end

  it "só quem tem ti.permissoes.conceder entra" do
    sign_in tecnico

    respostas = [ -> { get ti_permissoes_path }, -> { get edit_ti_permissao_path(maria) },
                  -> { patch ti_permissao_path(maria), params: { papeis: [ "tecnico" ] } } ]
                .map { |requisicao| requisicao.call && response.status }

    expect(respostas).to all(eq(403))
    expect(concedidos).to be_empty
  end

  context "com administrador da TI" do
    before { sign_in admin }

    it "lista os usuários ativos com as permissões e filtra" do
      tecnico

      get ti_permissoes_path
      expect(response.body).to include("MARIA OLIVEIRA", "Sem permissão (só abre chamados)", "TECNICO DA TI", "Técnico", "3 usuário(s) encontrado(s)")

      get ti_permissoes_path, params: { situacao: "com", q: "tecnico" }
      expect(response.body).to include("TECNICO DA TI", "1 usuário(s) encontrado(s)")
    end

    it "mostra o painel com uma caixa por permissão, marcando as atuais" do
      create(:core_concessao, user: maria, modulo: "ti", papel: "triagem")

      get edit_ti_permissao_path(maria)

      expect(response.body).to include("Gerenciar permissões de MARIA OLIVEIRA", "Administrador", "Supervisor", "Triador", "Técnico")
      expect(response.body).not_to include("Solicitante</span>")
      marcadas = Nokogiri::HTML(response.body).css("input[name='papeis[]'][checked]").map { |campo| campo["value"] }
      expect(marcadas).to eq([ "triagem" ])
    end

    it "acumula, troca e tira permissões" do
      patch ti_permissao_path(maria), params: { papeis: [ "", "triagem", "tecnico" ] }
      expect(concedidos).to contain_exactly("triagem", "tecnico")
      expect(response).to redirect_to(ti_permissoes_path)

      patch ti_permissao_path(maria), params: { papeis: [ "", "tecnico", "supervisor" ] }
      expect(concedidos).to contain_exactly("tecnico", "supervisor")

      patch ti_permissao_path(maria), params: { papeis: [ "" ] }
      expect(Core::Autorizacao.new(maria).papeis(:ti)).to eq([ "solicitante" ])
    end

    it "avisa a pessoa e registra na auditoria" do
      patch ti_permissao_path(maria), params: { papeis: [ "tecnico" ] }

      expect(maria.notificacoes.sole.mensagem).to include("Permissão Técnico no módulo TI")
      expect(Core::RegistroAuditoria.recentes.first).to have_attributes(evento: "acesso.papel_concedido", ator: admin, alvo_id: maria.id)
    end

    it "ignora papel de outro módulo e o automático" do
      patch ti_permissao_path(maria), params: { papeis: %w[superadmin solicitante] }

      expect(Core::Concessao.where(user: maria)).to be_empty
    end
  end

  it "supervisor não concede permissões" do
    supervisor = create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "supervisor") }

    resultado = Core::Api.definir_papeis(user: maria, modulo: :ti, papeis: [ "tecnico" ], definido_por: supervisor)

    expect(resultado).to be_falha
    expect(concedidos).to be_empty
  end

  it "não desfaz nada quando um dos papéis novos não pode ser concedido" do
    create(:core_concessao, user: maria, modulo: "ti", papel: "triagem")

    resultado = Core::Api.definir_papeis(user: maria, modulo: :ti, papeis: %w[tecnico inexistente], definido_por: admin)

    expect(resultado).to be_falha
    expect(concedidos).to eq([ "triagem" ])
  end
end
