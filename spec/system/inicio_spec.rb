require "rails_helper"

RSpec.describe "Início", :js do
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA") }

  before { sign_in maria }

  it "atualiza sozinho quando chega uma notificação, e o atalho abre o chamado num painel por cima" do
    visit root_path
    expect(page).to have_content("Tudo em dia")
    expect(page).to have_no_css("turbo-cable-stream-source:not([connected])", visible: :all)

    Core::Api.notificar(destinatarios: maria, evento: "core.teste.aviso", titulo: "Aviso de teste", ator: nil)

    expect(page).to have_css("#atencao a", text: "Notificações não lidas")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/inicio.png") if ENV["SCREENSHOT_DIR"]
    click_on "Abrir chamado de TI"
    expect(page).to have_css("#painel_titulo")
    expect(page).to have_current_path(root_path)
  end

  it "no celular fica numa coluna, sem rolagem horizontal" do
    usar_tela_de_celular
    visit root_path
    expect(page).to have_css("#links_uteis")
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/inicio-celular.png") if ENV["SCREENSHOT_DIR"]
    expect(sem_rolagem_horizontal?).to be(true)
  end
end
