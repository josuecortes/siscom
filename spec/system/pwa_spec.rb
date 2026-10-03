require "rails_helper"

RSpec.describe "App instalável (PWA)", :js do
  before { sign_in create(:user) }

  it "registra o service worker e mostra a situação dos avisos do aparelho" do
    visit notificacoes_path

    registrado = page.evaluate_async_script(<<~JS)
      const pronto = arguments[arguments.length - 1];
      navigator.serviceWorker.ready.then((registro) => pronto(registro.scope)).catch(() => pronto(null));
    JS
    expect(registrado).to end_with("/")

    within("[data-controller='push']") do
      expect(page).to have_no_content("Verificando este aparelho")
      expect(page).to have_css("button", text: /Ativar avisos neste aparelho|Desativar neste aparelho/).or have_content(/bloqueados|não recebe avisos/)
    end
    page.save_screenshot("#{ENV['SCREENSHOT_DIR']}/push.png") if ENV["SCREENSHOT_DIR"]
  end

  it "o navegador reconhece o manifesto do app" do
    visit root_path

    manifesto = page.evaluate_async_script(<<~JS)
      const pronto = arguments[arguments.length - 1];
      fetch(document.querySelector("link[rel='manifest']").href).then((r) => r.json()).then(pronto);
    JS

    expect(manifesto).to include("display" => "standalone", "short_name" => "Siscom")
  end
end
