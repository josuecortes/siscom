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
    visit transporte_solicitacao_path(solicitacao)
    expect(page).to have_content("Aguardando a aprovação do setor de transporte")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("1 solicitação(ões) em solicitadas") # chegou sozinha
      print("transporte-operacao")
      within("tr", text: solicitacao.codigo) { click_on "Visualizar solicitação" }
      expect(page).to have_css("h1", text: "Solicitação #{solicitacao.codigo}")
      click_on "Aprovar solicitação"
      expect(page).to have_css("#avisos", text: "aprovada")
    end

    expect(page).to have_content("Solicitação aprovada") # mudou sozinha para a Maria
    expect(page).to have_content("Aprovada")

    Capybara.using_session(:tecnico) do
      click_on "Reagendar"
      fill_in "Motivo *", with: "Veículo em manutenção"
      within("[role='dialog']") { click_on "Salvar horários" }
      expect(page).to have_css("#avisos", text: "reagendada")
      print("transporte-operacao-solicitacao")
    end

    click_on "Cancelar solicitação"
    fill_in "Motivo *", with: "Reunião desmarcada"
    within("[role='dialog']") { click_on "Cancelar solicitação" }
    expect(page).to have_css("#avisos", text: "cancelada")

    Capybara.using_session(:tecnico) do
      expect(page).to have_content("Cancelada") # o técnico vê o cancelamento sem recarregar
      expect(page).to have_content("Reunião desmarcada")
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
