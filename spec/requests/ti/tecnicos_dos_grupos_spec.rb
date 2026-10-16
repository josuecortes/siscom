require "rails_helper"

# TI → Grupos técnicos → aba Técnicos: o vínculo grupo × técnico visto pelo lado da pessoa.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe "TI: grupos técnicos por técnico" do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: papel) }

  let(:supervisor) { com_papel("supervisor", "SUPERVISOR DA TI") }
  let(:joao) { com_papel("tecnico", "JOÃO CONCEIÇÃO") }
  let(:maria) { create(:user, nome: "MARIA SEM PERMISSAO") }
  let!(:redes) { create(:ti_grupo_tecnico, nome: "REDES") }
  let!(:sistemas) { create(:ti_grupo_tecnico, nome: "SISTEMAS") }
  let!(:suporte) { create(:ti_grupo_tecnico, nome: "SUPORTE") }
  let(:painel) { { "Turbo-Frame" => "painel" } }

  def pagina = Nokogiri::HTML(response.body)
  def nomes = pagina.css("tbody tr[id] td:first-child p:first-child").map { |celula| celula.text.strip }
  def grupos_de(user) = Ti::MembroGrupo.where(user: user).joins(:grupo_tecnico).order("ti_grupos_tecnicos.nome").pluck("ti_grupos_tecnicos.nome")

  it "quem não gerencia o catálogo da TI não entra" do
    sign_in joao

    get ti_tecnicos_dos_grupos_path

    expect(response).to have_http_status(:forbidden)
  end

  context "com o supervisor" do
    before { sign_in supervisor }

    it "a tela Grupos técnicos ganha as abas, e a lista de grupos continua a mesma" do
      get ti_grupos_tecnicos_path

      expect(pagina.css("nav[aria-label='Grupos técnicos'] a").map { |aba| [ aba.text.strip, aba["aria-current"] ] }).to eq([ [ "Grupos", "page" ], [ "Técnicos", nil ] ])
      expect(response.body).to include("REDES", "Gerenciar membros", "Gerenciar solicitações")
    end

    it "sem busca lista quem já está em grupo; com busca, quem tem permissão na TI, sem diferenciar acento" do
      Ti::Grupos::DefinirDoUsuario.call(user: supervisor, grupo_ids: [ redes.id, suporte.id ], definido_por: supervisor)
      joao
      maria

      get ti_tecnicos_dos_grupos_path
      expect(nomes).to eq([ "SUPERVISOR DA TI" ])
      expect(response.body).to include("2 grupo(s)", "REDES, SUPORTE", "Supervisor")
      get ti_tecnicos_dos_grupos_path(q: "joao conceicao")
      expect(nomes).to eq([ "JOÃO CONCEIÇÃO" ])
      get ti_tecnicos_dos_grupos_path(q: "maria")
      expect(nomes).to be_empty
    end

    it "inclui em vários grupos de uma vez, avisa a pessoa uma vez só e registra na auditoria" do
      patch adicionar_ti_tecnico_dos_grupos_path(joao), params: { grupo_ids: [ redes.id, sistemas.id ] }, headers: painel

      expect(grupos_de(joao)).to eq(%w[REDES SISTEMAS])
      expect(pagina.css("#grupos_do_tecnico li").map { |item| item.css("span span").first.text.strip }).to eq(%w[REDES SISTEMAS])
      expect(joao.notificacoes.pluck(:titulo, :mensagem)).to eq([ [ "Você entrou em grupos técnicos", "Você agora faz parte dos grupos técnicos REDES e SISTEMAS da TI." ] ])
      expect(Core::RegistroAuditoria.where(evento: "grupo_tecnico.membro_alterado").count).to eq(1)
    end

    it "remove vários marcados de uma vez, ou só um pelo ×" do
      Ti::Grupos::DefinirDoUsuario.call(user: joao, grupo_ids: [ redes.id, sistemas.id, suporte.id ], definido_por: supervisor)

      patch remover_ti_tecnico_dos_grupos_path(joao), params: { grupo_ids: [ redes.id, sistemas.id ] }, headers: painel
      expect(grupos_de(joao)).to eq(%w[SUPORTE])
      patch remover_ti_tecnico_dos_grupos_path(joao), params: { so: suporte.id }, headers: painel
      expect(grupos_de(joao)).to be_empty
    end

    it "quem não tem permissão na TI não entra em grupo (o painel avisa) e sem nada marcado não muda nada" do
      get edit_ti_tecnico_dos_grupos_path(maria), headers: painel
      expect(pagina.at_css("#sem_permissao").text).to include("não tem permissão na TI")
      expect(pagina.css("#adicionar_grupos input[name='grupo_ids[]']")).to be_empty

      patch adicionar_ti_tecnico_dos_grupos_path(maria), params: { grupo_ids: [ redes.id ] }, headers: painel
      expect([ response.status, grupos_de(maria) ]).to eq([ 422, [] ])
      patch adicionar_ti_tecnico_dos_grupos_path(joao), headers: painel
      expect(pagina.css("[data-faixa-aviso='erro']").text.squish).to eq("Marque pelo menos um grupo para adicionar.")
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
