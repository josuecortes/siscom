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

  # Posição e tamanho de um elemento na tela, com uma casa decimal: { "x", "y", "largura", "altura" }.
  def retangulo(seletor)
    page.assert_selector(:css, seletor, visible: :all, minimum: 1) # espera o elemento existir (a página pode estar carregando)
    page.evaluate_script(<<~JS)
      (() => {
        const r = document.querySelector(#{seletor.to_json}).getBoundingClientRect();
        const n = (valor) => Math.round(valor * 10) / 10;
        return { x: n(r.x), y: n(r.y), largura: n(r.width), altura: n(r.height) };
      })()
    JS
  end

  # Largura e altura de vários elementos de uma vez: { nome => seletor } vira { nome => [ largura, altura ] }.
  def tamanhos(seletores)
    seletores.transform_values { |seletor| retangulo(seletor).values_at("largura", "altura") }
  end

  # Valor calculado de uma propriedade CSS (nome em camelCase, como no JavaScript).
  def estilo(seletor, propriedade)
    page.evaluate_script("getComputedStyle(document.querySelector(#{seletor.to_json}))[#{propriedade.to_json}]")
  end

  # Fixa o tema ("light" ou "dark") e recarrega a página aberta (recarregar evita
  # medir cores no meio da transição de 160 ms).
  def usar_tema(tema)
    page.execute_script("localStorage.setItem('siscom-tema', #{tema.to_json})")
    page.refresh
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
    # Sem barras de rolagem ocupando espaço: no macOS elas aparecem (15 px) quando há um mouse ligado,
    # e as medidas dos specs mudariam de uma máquina para outra.
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]) { |opcoes| opcoes.add_argument("--hide-scrollbars") }
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

# Campo de busca com sugestões (compartilhado/_campo_autocomplete): digita e escolhe na lista.
module AjudantesDeAutocomplete
  def escolher_no_autocomplete(rotulo, digitar:, opcao:)
    campo = find_field(rotulo)
    campo.fill_in(with: digitar)
    lista = find("##{campo[:id]}_lista", visible: :visible)
    lista.find("[role='option']", text: opcao, match: :prefer_exact).click
    expect(campo.value).to eq(opcao)
  end
end

RSpec.configure { |config| config.include AjudantesDeAutocomplete, type: :system }
