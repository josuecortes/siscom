require "rails_helper"

RSpec.describe "TI: campos da solicitação", :js do
  let(:admin) { create(:user).tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "admin") } }
  let!(:solicitacao) { create(:ti_problema, nome: "Prodoc - Cadastro") }

  before { sign_in admin }

  it "monta o formulário: o tipo escolhido mostra só os campos que valem para ele" do
    visit ti_solicitacoes_path
    within("tr", text: "PRODOC - CADASTRO") { click_on "Campos da solicitação" }
    expect(page).to have_css("h1", text: "Campos do chamado PRODOC - CADASTRO")

    click_on "Novo campo"
    expect(page).to have_field("Máscara")
    expect(page).to have_no_field("Opções * (uma por linha)")
    expect(page).to have_no_field("Fonte de dados *")

    fill_in "Nome *", with: "Perfil no Prodoc"
    select "Seleção (lista)", from: "Tipo *"
    expect(page).to have_no_field("Máscara")
    fill_in "Opções * (uma por linha)", with: "Responsável por unidade\nAuxiliar do responsável"
    check "Campo obrigatório"
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/ti-campo-painel.png") if ENV["SCREENSHOT_DIR"]
    click_on "Salvar campo"

    expect(page).to have_css("#avisos", text: "Campo criado com sucesso.")
    within("tr", text: "Perfil no Prodoc") { expect(page).to have_content("Seleção (lista)").and have_content("Responsável por unidade, Auxiliar do responsável") }

    click_on "Novo campo"
    fill_in "Nome *", with: "Unidade de destino"
    select "Busca (uma opção)", from: "Tipo *"
    select "RH > Unidades", from: "Fonte de dados *"
    click_on "Salvar campo"

    expect(page).to have_css("#avisos", text: "Campo criado com sucesso.")
    expect(solicitacao.campos.ordenados.pluck(:chave, :tipo)).to eq([ %w[perfil_no_prodoc selecao], %w[unidade_de_destino busca] ])
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/ti-campos-lista.png") if ENV["SCREENSHOT_DIR"]
  end

  it "no celular a lista e o painel não criam rolagem horizontal" do
    create(:ti_campo_problema, problema: solicitacao, rotulo: "Nome completo")
    usar_tela_de_celular
    visit ti_solicitacao_campos_path(solicitacao)
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Novo campo"
    expect(page).to have_css("[role='dialog'] h2", text: "Novo campo")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
