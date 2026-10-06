require "rails_helper"

RSpec.describe "Transporte: operação em tempo real", :js do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:tecnico) { com_papel("tecnico", "TECNICO DO TRANSPORTE") }
  let(:dados) do
    { tipo: "normal", modo: "so_deixar", resumo: "Reunião na SEAD", saida_em: 60.hours.from_now, passageiros: [ { cpf: "529.982.247-25", nome: "Maria" } ],
      destinos: [ { nome: "SEAD", logradouro: "Avenida FAB", numero: "96", bairro: "Central", cidade: "Macapá", uf: "AP" } ] }
  end

  before { Rh::Tabelas.garantir_padroes }

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "o técnico vê o pedido chegar, aprova e reagenda; o solicitante acompanha sem recarregar" do
    Capybara.using_session(:tecnico) do
      sign_in tecnico
      visit transporte_operacao_index_path
      expect(page).to have_content("0 solicitação(ões) em solicitadas")
    end

    solicitacao = Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados).objeto
    sign_in maria
    visit transporte_solicitacoes_path
    expect(page).to have_content("1 solicitação(ões) em solicitadas")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("1 solicitação(ões) em solicitadas") # chegou sozinha
      print("transporte-operacao")
      within("tr", text: solicitacao.codigo) { click_on "Visualizar solicitação" }
      within("[role='dialog']") do # "ver" abre no painel, por cima da lista
        expect(page).to have_css("h2", text: "Solicitação #{solicitacao.codigo}").and have_content("Histórico")
        print("transporte-operacao-solicitacao")
        click_on "Fechar"
      end
      within("tr", text: solicitacao.codigo) { click_on "Aprovar solicitação" }
      within("#confirmacao") { click_on "Aprovar" }
      expect(page).to have_css("#avisos", text: "aprovada")
    end

    expect(page).to have_css("nav a", text: /Aprovadas\s*1/) # mudou sozinha para a Maria

    Capybara.using_session(:tecnico) do
      click_on "Aprovadas"
      within("tr", text: solicitacao.codigo) { click_on "Reagendar" }
      fill_in "Nova saída (data e hora) *", with: I18n.l(70.hours.from_now, format: "%d%m%Y%H%M")
      fill_in "Motivo *", with: "Veículo em manutenção"
      within("[role='dialog']") { click_on "Enviar reagendamento" }
      expect(page).to have_css("#avisos", text: "aguardando a resposta do solicitante")
      expect(page).to have_css("nav a", text: /Reagendadas\s*1/)
    end

    # O solicitante vê o reagendamento chegar e aceita o novo horário.
    expect(page).to have_css("nav a", text: /Reagendadas\s*1/)
    click_on "Reagendadas"
    within("tr", text: solicitacao.codigo) { click_on "Responder ao reagendamento" }
    within("[role='dialog']") do
      expect(page).to have_content("Veículo em manutenção").and have_content("TECNICO DO TRANSPORTE")
      print("transporte-responder-reagendamento")
      click_on "Aceitar novo horário"
    end
    expect(page).to have_css("#avisos", text: "Reagendamento aceito")

    click_on "Aprovadas"
    within("tr", text: solicitacao.codigo) { click_on "Cancelar solicitação" }
    fill_in "Motivo *", with: "Reunião desmarcada"
    within("[role='dialog']") { click_on "Cancelar solicitação" }
    expect(page).to have_css("#avisos", text: "cancelada")

    Capybara.using_session(:tecnico) do
      expect(page).to have_css("nav a", text: /Canceladas\s*1/) # o técnico vê o cancelamento sem recarregar
      click_on "Canceladas"
      within("tr", text: solicitacao.codigo) { click_on "Visualizar solicitação" }
      expect(page).to have_css("[role='dialog']", text: "Reunião desmarcada")
    end
  end

  it "no celular os filtros ficam recolhidos atrás de Mais filtros; a busca continua à vista" do
    Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados)
    sign_in tecnico
    usar_tela_de_celular
    visit transporte_operacao_index_path

    expect(page).to have_field("Buscar por código, resumo ou solicitante")
    expect(page).to have_no_field("Tipo").and have_no_field("Pedido de")
    altura_recolhido = retangulo("#filtros_da_operacao")["altura"]

    click_on "Mais filtros"
    expect(page).to have_field("Tipo").and have_field("Unidade de quem pediu").and have_field("Pedido de").and have_field("Saída até")
    expect(retangulo("#filtros_da_operacao")["altura"]).to be > altura_recolhido + 200
    expect(sem_rolagem_horizontal?).to be(true)
    print("transporte-operacao-filtros-celular")

    select "Normal", from: "Tipo" # o filtro aplica e o bloco continua aberto, com o contador no botão ao recarregar
    expect(page).to have_css("nav [aria-current='page']", text: /Resultado\s*1/)
    expect(page).to have_field("Tipo")
    click_on "Mais filtros"
    expect(page).to have_no_field("Tipo")
    expect(altura_recolhido).to be < 160
  end

  it "no computador os filtros aparecem sempre e a ordem troca pelo cabeçalho da coluna" do
    primeira = Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados).objeto
    segunda = Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados.merge(saida_em: 55.hours.from_now)).objeto # pedida depois, sai antes
    sign_in tecnico
    visit transporte_operacao_index_path

    codigos = -> { all("#operacao_lista tbody tr td:first-child a").map(&:text) }
    expect(page).to have_field("Tipo").and have_no_button("Mais filtros")
    expect(codigos.call).to eq([ segunda.codigo, primeira.codigo ])

    click_on "Pedido em"
    expect(page).to have_css("th[aria-sort='ascending']", text: "Pedido em")
    expect(codigos.call).to eq([ primeira.codigo, segunda.codigo ])
    click_on "Pedido em"
    expect(page).to have_css("th[aria-sort='descending']", text: "Pedido em")
    expect(codigos.call).to eq([ segunda.codigo, primeira.codigo ])

    fill_in "Buscar por código, resumo ou solicitante", with: "maria" # a busca mantém a ordem escolhida
    expect(page).to have_css("nav [aria-current='page']", text: /Resultado\s*2/)
    expect(page).to have_css("th[aria-sort='descending']", text: "Pedido em")
  end

  it "campo de data tem calendário, sem tirar a digitação; com hora, o calendário também escolhe a hora" do
    solicitacao = Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados).objeto
    solicitacao.update!(status: "aprovada")
    sign_in tecnico
    visit transporte_operacao_index_path

    # Só data (filtro): o botão existe, a escolha entra em dd/mm/aaaa, e digitar continua funcionando.
    expect(page).to have_button("Abrir calendário", count: 4)
    escolher = ->(campo, valor) { page.execute_script("const n = document.querySelector('##{campo}').parentElement.querySelector('[data-calendario-nativo]'); n.value = '#{valor}'; n.dispatchEvent(new Event('change'))") }
    escolher.call("saida_de", "2026-10-01")
    expect(page).to have_field("Saída de", with: "01/10/2026")
    fill_in "Saída até", with: "31122026"
    expect(page).to have_field("Saída até", with: "31/12/2026")
    expect(page.evaluate_script("document.querySelector('#saida_de').parentElement.querySelector('[data-calendario-nativo]').type")).to eq("date")

    # Data e hora (reagendar): o seletor do navegador é o de data e hora.
    visit transporte_operacao_index_path(status: "aprovada")
    within("tr", text: solicitacao.codigo) { click_on "Reagendar" }
    expect(page).to have_button("Abrir calendário e hora")
    expect(page.evaluate_script("document.querySelector('#saida_em').parentElement.querySelector('[data-calendario-nativo]').type")).to eq("datetime-local")
    escolher.call("saida_em", "2026-12-24T14:30")
    expect(page).to have_field("Nova saída (data e hora) *", with: "24/12/2026 14:30")
  end

  it "no celular a operação não cria rolagem horizontal" do
    Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados)
    sign_in tecnico
    usar_tela_de_celular
    visit transporte_operacao_index_path
    expect(page).to have_content("1 solicitação(ões) em solicitadas")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
