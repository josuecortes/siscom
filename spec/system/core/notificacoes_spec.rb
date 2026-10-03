require "rails_helper"

RSpec.describe "Notificações", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }
  let(:maria) { create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br") }

  it "chega em tempo real no sino de quem recebeu um papel, sem recarregar a página" do
    Capybara.using_session(:maria) do
      sign_in maria
      visit root_path
      expect(page).to have_css("#sino_notificacoes")
      expect(page).to have_no_css("[data-sino-contador]")
      expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all)
    end

    sign_in superadmin
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Acessos e papéis" }
    within("#acesso_core") do
      select "Auditor", from: "Conceder papel em Administração"
      click_on "Conceder papel em Administração"
    end
    expect(page).to have_content("Papel concedido.")

    Capybara.using_session(:maria) do
      expect(page).to have_css("[data-sino-contador]", text: "1")
      expect(page).to have_css("#avisos", text: "Você recebeu um novo papel")

      click_on "Abrir notificações (1 não lidas)"
      expect(page).to have_content("Papel Auditor no módulo Administração.")
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/sino.png") if ENV["SCREENSHOT_DIR"]

      click_on "Ver todas as notificações"
      expect(page).to have_css("h1", text: "Notificações")
      click_on "Marcar tudo como lido"
      expect(page).to have_content("0 notificação(ões) não lida(s)")
      expect(page).to have_no_css("[data-sino-contador]")
    end
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "o painel do sino cabe na tela" do
      Core::Notificacoes::Criar.call(destinatarios: maria, evento: "core.acesso.papel_concedido", titulo: "Novo papel", ator: nil)
      sign_in maria
      visit root_path

      click_on "Abrir notificações (1 não lidas)"

      painel = retangulo("#sino_notificacoes [data-dropdown-target='menu']")
      expect(painel["x"]).to be >= 0
      expect(painel["x"] + painel["largura"]).to be <= 390
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/sino-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
