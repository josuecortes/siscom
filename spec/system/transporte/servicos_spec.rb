require "rails_helper"

RSpec.describe "Transporte: o motorista faz o serviço", :js do
  def com_papel(papel, nome) = create(:user, nome: nome).tap { |u| create(:core_concessao, user: u, modulo: "transporte", papel: papel) }

  let(:maria) { com_papel("solicitante", "MARIA OLIVEIRA") }
  let(:joao) { com_papel("motorista", "JOAO MOTORISTA") }
  let!(:solicitacao) do
    Transporte::Solicitacao.create!(tipo: "normal", modo: "so_deixar", status: "aprovada", resumo: "Reunião na SEAD", saida_em: 1.hour.from_now,
                                    solicitante: maria, solicitante_nome: maria.nome, solicitante_email: maria.email)
  end

  before { create(:transporte_veiculo, placa: "QLM1A23", odometro_atual: 12_000) }

  def print(nome)
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/#{nome}.png") if ENV["SCREENSHOT_DIR"]
  end

  it "inicia com veículo e odômetro, finaliza, e o solicitante acompanha sem recarregar" do
    sign_in maria
    visit transporte_solicitacao_path(solicitacao)
    expect(page).to have_content("Aprovada")

    Capybara.using_session(:motorista) do
      sign_in joao
      visit root_path
      within("#menu-lateral") do
        find("summary", text: "Transporte").click
        click_on "Meus serviços"
      end
      within("tr", text: solicitacao.codigo) { click_on "Visualizar solicitação" }
      click_on "Iniciar serviço"
      escolher_no_autocomplete "Veículo *", digitar: "qlm", opcao: "QLM1A23 · TOYOTA HILUX"
      fill_in "Odômetro inicial (km) *", with: "12050"
      print("transporte-iniciar-servico")
      within("[role='dialog']") { click_on "Iniciar serviço" }
      expect(page).to have_css("#avisos", text: "Serviço iniciado. Boa viagem!")
      expect(page).to have_content("em andamento")
    end

    expect(page).to have_content("Em serviço") # mudou sozinha para a Maria
    expect(page).to have_content("JOAO MOTORISTA · QLM1A23")

    Capybara.using_session(:motorista) do
      click_on "Concluir serviço"
      fill_in "Odômetro final (km) *", with: "12080"
      within("[role='dialog']") { click_on "Concluir serviço" }
      expect(page).to have_css("#avisos", text: "Trecho finalizado.")
      expect(page).to have_content("30 km rodados")
      print("transporte-servico")
    end

    expect(page).to have_content("Concluída")
  end

  it "no celular a lista do motorista não cria rolagem horizontal" do
    sign_in joao
    usar_tela_de_celular
    visit transporte_servicos_path
    expect(page).to have_content(solicitacao.codigo)
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
