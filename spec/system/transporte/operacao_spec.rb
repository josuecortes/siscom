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

  it "no celular a operação não cria rolagem horizontal" do
    Transporte::Solicitacoes::Abrir.call(user: maria, atributos: dados)
    sign_in tecnico
    usar_tela_de_celular
    visit transporte_operacao_index_path
    expect(page).to have_content("1 solicitação(ões) em solicitadas")
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
