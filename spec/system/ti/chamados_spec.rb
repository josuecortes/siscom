require "rails_helper"

RSpec.describe "TI: abrir chamado", :js do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }
  let(:geral) { create(:ti_perfil_abertura, nome: "Geral", padrao: true) }

  before do
    Rh::Tabelas.garantir_padroes
    Core::Api.publicar_fontes_padrao
    create(:rh_unidade, nome: "Núcleo de Informática", sigla: "NUINFO")
    acesso = create(:ti_problema, nome: "Sigdoc - Solicitar acesso", descricao: "Pedido de acesso ao Sigdoc", categoria: create(:ti_categoria, nome: "Sistemas web"))
    { "Nome completo" => { obrigatorio: true }, "Celular" => { mascara: "celular" }, "Nascimento" => { tipo: "data" },
      "Unidade" => { tipo: "busca", fonte: "rh_unidades", obrigatorio: true }, "Perfil" => { tipo: "selecao_unica", opcoes: "Leitor\nEditor" } }.each do |rotulo, atributos|
      acesso.campos.new(tipo: atributos.fetch(:tipo, "texto")).update!(atributos.merge(rotulo: rotulo))
    end
    internet = create(:ti_problema, nome: "Sem internet", categoria: create(:ti_categoria, nome: "Rede"))
    [ acesso, internet ].each { |solicitacao| solicitacao.perfis_abertura << geral }
    sign_in maria
  end

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "escolhe a solicitação, preenche o formulário dela e acompanha em Meus chamados" do
    visit root_path
    within("#menu-lateral") do
      find("summary", text: "TI").click
      click_on "Meus chamados"
    end
    click_on "Abrir chamado"
    expect(page).to have_css("[role='dialog'] h2", text: "Abrir chamado")
    expect(page).to have_no_field("Nome completo *")

    select "SIGDOC - SOLICITAR ACESSO", from: "Solicitação *"
    expect(page).to have_no_content("Pedido de acesso ao Sigdoc")
    fill_in "Nome completo *", with: "Ana Paula"
    fill_in "Celular", with: "96991234567"
    expect(find_field("Celular").value).to eq("(96) 99123-4567")
    fill_in "Nascimento", with: "15011985"
    expect(find_field("Nascimento").value).to eq("15/01/1985")
    escolher_no_autocomplete "Unidade *", digitar: "inform", opcao: "NÚCLEO DE INFORMÁTICA"
    choose "Editor"
    print("ti-abrir-chamado")
    within("[role='dialog']") { click_on "Abrir chamado" }

    chamado = nil
    expect(page).to have_css("#avisos", text: /Chamado TI-\d{6} aberto com sucesso\./)
    chamado = Ti::Chamado.sole
    within("tr", text: chamado.codigo) do
      expect(page).to have_content("SIGDOC - SOLICITAR ACESSO").and have_content("Aberto")
      click_on "Visualizar chamado"
    end
    expect(page).to have_css("h1", text: "Chamado #{chamado.codigo}")
    expect(page).to have_content("Ana Paula").and have_content("(96) 99123-4567").and have_content("NÚCLEO DE INFORMÁTICA").and have_content("Editor")
    print("ti-chamado")
  end

  it "trocar a solicitação troca o formulário" do
    visit new_ti_chamado_path
    select "SIGDOC - SOLICITAR ACESSO", from: "Solicitação *"
    expect(page).to have_field("Nome completo *")

    select "SEM INTERNET", from: "Solicitação *"
    expect(page).to have_no_field("Nome completo *")
    click_on "Abrir chamado"

    expect(page).to have_css("#avisos", text: "aberto com sucesso")
    expect(Ti::Chamado.sole.problema.nome).to eq("SEM INTERNET")
  end

  it "com muitas solicitações, a escolha vira campo de busca e também carrega o formulário" do
    hardware = create(:ti_categoria, nome: "Hardware")
    8.times { |n| create(:ti_problema, nome: "Defeito #{n}", categoria: hardware).perfis_abertura << geral }

    visit new_ti_chamado_path
    escolher_no_autocomplete "Solicitação *", digitar: "sigdoc", opcao: "SIGDOC - SOLICITAR ACESSO"

    expect(page).to have_field("Nome completo *")
    expect(find_field("Solicitação *").value).to eq("SIGDOC - SOLICITAR ACESSO")
  end

  it "o técnico abre o chamado em nome de outra pessoa, escolhida por busca" do
    tecnico = create(:user, nome: "JOAO TECNICO").tap { |u| create(:core_concessao, user: u, modulo: "ti", papel: "tecnico") }
    Capybara.reset_sessions!
    sign_in tecnico

    visit root_path
    within("#menu-lateral") do
      find("summary", text: "TI").click
      click_on "Abrir para outra pessoa"
    end
    expect(page).to have_css("[role='dialog'] h2", text: "Abrir chamado para outra pessoa")
    expect(page).to have_no_field("Solicitação *")

    escolher_no_autocomplete "Pessoa *", digitar: "mar", opcao: "MARIA OLIVEIRA"
    select "SIGDOC - SOLICITAR ACESSO", from: "Solicitação *"
    fill_in "Nome completo *", with: "Maria Oliveira"
    escolher_no_autocomplete "Unidade *", digitar: "inform", opcao: "NÚCLEO DE INFORMÁTICA"
    print("ti-abrir-para-outro")
    click_on "Abrir chamado"

    expect(page).to have_css("#avisos", text: /aberto em nome de MARIA OLIVEIRA\./)
    expect(page).to have_css("h1", text: "Chamado #{Ti::Chamado.sole.codigo}")
    expect(page).to have_content("JOAO TECNICO (em nome do solicitante)")
    expect(Ti::Chamado.sole).to have_attributes(solicitante: maria, aberto_por: tecnico)
  end

  it "no celular a lista, o painel e o chamado não criam rolagem horizontal" do
    usar_tela_de_celular
    visit ti_chamados_path
    expect(sem_rolagem_horizontal?).to be(true)

    click_on "Abrir chamado"
    select "SIGDOC - SOLICITAR ACESSO", from: "Solicitação *"
    expect(page).to have_field("Nome completo *")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
