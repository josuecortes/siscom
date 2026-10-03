require "rails_helper"

RSpec.describe "Administração: auditoria", :js do
  let(:superadmin) { create(:user, nome: "ADMIN DA SILVA").tap { |u| create(:core_concessao, user: u, papel: "superadmin") } }

  before do
    create(:user, nome: "MARIA OLIVEIRA", email: "maria@seed.ap.gov.br")
    sign_in superadmin
  end

  it "mostra na auditoria o que acabou de ser feito na tela de usuários" do
    visit core_usuarios_path
    within("tr", text: "MARIA OLIVEIRA") { click_on "Desativar usuário" }
    within("#confirmacao") { click_on "Desativar usuário" }
    expect(page).to have_css("#avisos", text: "Usuário desativado com sucesso.")

    within("#menu-lateral") { click_on "Auditoria" }

    expect(page).to have_css("h1", text: "Auditoria")
    within("tbody tr:first-child") do
      expect(page).to have_content("Usuário desativado")
      expect(page).to have_content("ADMIN DA SILVA MARIA OLIVEIRA")
    end
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/auditoria.png") if ENV["SCREENSHOT_DIR"]

    select "Papel concedido", from: "Evento"
    expect(page).to have_content("Nenhum registro encontrado")
    expect(page).to have_current_path(/evento=core.acesso.papel_concedido/)
  end

  context "quando está no celular" do
    before { usar_tela_de_celular }

    it "não cria rolagem horizontal" do
      Core::Auditoria::Registrar.call(evento: "core.usuario.criado", alvo: superadmin, ator: superadmin)
      visit core_auditoria_path

      expect(page).to have_content("1 registro(s) de auditoria")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
      page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/auditoria-celular.png") if ENV["SCREENSHOT_DIR"]
    end
  end
end
