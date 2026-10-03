require "capybara/rspec"

Capybara.enable_aria_label = true

# Tamanho exato da área da página nos specs com navegador. A janela do Chrome
# não fica com menos de 500 px de largura, então `resize_to(390, ...)` não
# testa o celular de verdade; a emulação do DevTools sim.
module TamanhoDeTela
  def usar_tela(largura:, altura:, celular: false)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
                                    width: largura, height: altura, deviceScaleFactor: 1, mobile: celular)
  end

  # Celular de referência do projeto: 390 x 844.
  def usar_tela_de_celular
    usar_tela(largura: 390, altura: 844, celular: true)
  end

  # Posição e tamanho de um elemento na tela: { "x", "y", "largura", "altura" }.
  def retangulo(seletor)
    page.evaluate_script(<<~JS)
      (() => {
        const r = document.querySelector(#{seletor.to_json}).getBoundingClientRect();
        return { x: r.x, y: r.y, largura: r.width, altura: r.height };
      })()
    JS
  end

  # Valor calculado de uma propriedade CSS (nome em camelCase, como no JavaScript).
  def estilo(seletor, propriedade)
    page.evaluate_script("getComputedStyle(document.querySelector(#{seletor.to_json}))[#{propriedade.to_json}]")
  end

  def largura_da_tela
    page.evaluate_script("window.innerWidth")
  end

  def sem_rolagem_horizontal?
    page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")
  end
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
    # A janela é reaproveitada entre exemplos; volta ao tamanho de desktop.
    usar_tela(largura: 1400, altura: 900)
  end

  config.include TamanhoDeTela, type: :system
end

# Os specs de sistema usam o CSS compilado; recompila uma vez por execução
# para não testar com classes do Tailwind desatualizadas.
RSpec.configure do |config|
  config.before(:suite) do
    tem_sistema = RSpec.world.filtered_examples.values.flatten.any? { |exemplo| exemplo.metadata[:type] == :system }
    next unless tem_sistema && !ENV["CI"]

    system("bin/rails tailwindcss:build", out: File::NULL, exception: true)
  end
end
