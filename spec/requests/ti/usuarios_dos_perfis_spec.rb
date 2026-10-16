require "rails_helper"

# TI → Perfis de abertura → aba Usuários: o vínculo perfil × usuário visto pelo lado da pessoa.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe "TI: perfis de abertura por usuário" do
  let(:admin) { create(:user, nome: "ADMIN DA TI").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }
  let(:joao) { create(:user, nome: "JOÃO CONCEIÇÃO", email: "joao@seed.ap.gov.br") }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let!(:escolar) { create(:ti_perfil_abertura, nome: "SOLICITANTE ESCOLAR") }
  let!(:sede) { create(:ti_perfil_abertura, nome: "SOLICITANTE DA SEDE") }
  let!(:diretor) { create(:ti_perfil_abertura, nome: "DIRETOR") }
  let!(:todos) { create(:ti_perfil_abertura, nome: "TODOS OS SERVIDORES", padrao: true) }
  let(:painel) { { "Turbo-Frame" => "painel" } }

  def pagina = Nokogiri::HTML(response.body)
  def nomes = pagina.css("tbody tr[id] td:first-child p:first-child").map { |celula| celula.text.strip }
  def perfis_de(user) = Ti::PerfilUsuario.where(user: user).joins(:perfil_abertura).order("ti_perfis_abertura.nome").pluck("ti_perfis_abertura.nome")

  it "quem não pode dar permissões na TI não vê a aba nem mexe" do
    sign_in create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }

    respostas = [ -> { get ti_usuarios_dos_perfis_path }, -> { patch adicionar_ti_usuario_dos_perfis_path(joao), params: { perfil_ids: [ sede.id ] } } ].map { |requisicao| requisicao.call && response.status }

    expect(respostas).to eq([ 403, 403 ])
    expect(perfis_de(joao)).to be_empty
  end

  context "com o administrador da TI" do
    before { sign_in admin }

    it "a tela Perfis ganha as abas, e a lista de perfis continua a mesma" do
      get ti_perfis_abertura_path

      expect(pagina.css("nav[aria-label='Perfis de abertura'] a").map { |aba| [ aba.text.strip, aba["aria-current"] ] }).to eq([ [ "Perfis", "page" ], [ "Usuários", nil ] ])
      expect(response.body).to include("SOLICITANTE ESCOLAR", "Gerenciar usuários", "Gerenciar solicitações")
    end

    it "sem busca lista quem já está em algum perfil; com busca, qualquer usuário ativo, sem diferenciar acento" do
      Ti::Perfis::DefinirDoUsuario.call(user: maria, perfil_ids: [ escolar.id, diretor.id ], definido_por: admin)
      joao

      get ti_usuarios_dos_perfis_path
      expect(nomes).to eq([ "MARIA OLIVEIRA" ])
      expect(response.body).to include("2 perfil(is)", "DIRETOR, SOLICITANTE ESCOLAR")
      get ti_usuarios_dos_perfis_path(q: "joao conceicao")
      expect(nomes).to eq([ "JOÃO CONCEIÇÃO" ])
      expect(response.body).to include("Nenhum")
    end

    it "inclui em vários perfis de uma vez e mostra embaixo onde a pessoa está; o padrão só aparece como informação" do
      get edit_ti_usuario_dos_perfis_path(joao), headers: painel
      expect(pagina.css("#adicionar_perfis input[name='perfil_ids[]']").pluck("value").map(&:to_i)).to contain_exactly(escolar.id, sede.id, diretor.id)
      expect(pagina.css("#perfis_padrao").text).to include("TODOS OS SERVIDORES")

      patch adicionar_ti_usuario_dos_perfis_path(joao), params: { perfil_ids: [ escolar.id, sede.id, todos.id ] }, headers: painel

      expect(perfis_de(joao)).to eq([ "SOLICITANTE DA SEDE", "SOLICITANTE ESCOLAR" ])
      expect(pagina.css("#perfis_do_usuario li").map { |item| item.css("span span").first.text.strip }).to eq([ "SOLICITANTE DA SEDE", "SOLICITANTE ESCOLAR" ])
      expect([ response.body.include?("JOÃO CONCEIÇÃO entrou em 2 perfil(is)."), Core::RegistroAuditoria.where(evento: "perfil_abertura.usuario_alterado").count ]).to eq([ true, 1 ])
    end

    it "remove vários marcados de uma vez, ou só um pelo ×" do
      Ti::Perfis::DefinirDoUsuario.call(user: joao, perfil_ids: [ escolar.id, sede.id, diretor.id ], definido_por: admin)

      patch remover_ti_usuario_dos_perfis_path(joao), params: { perfil_ids: [ escolar.id, sede.id ] }, headers: painel
      expect(perfis_de(joao)).to eq([ "DIRETOR" ])

      patch remover_ti_usuario_dos_perfis_path(joao), params: { so: diretor.id }, headers: painel
      expect(perfis_de(joao)).to be_empty
      expect(response.body).to include("JOÃO CONCEIÇÃO saiu de 1 perfil(is).", "ainda não está em nenhum perfil de abertura")
    end

    it "sem nada marcado, avisa e não muda nada" do
      patch adicionar_ti_usuario_dos_perfis_path(joao), headers: painel

      expect(response).to have_http_status(:unprocessable_content)
      expect(pagina.css("[data-faixa-aviso='erro']").text.squish).to eq("Marque pelo menos um perfil para adicionar.")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
