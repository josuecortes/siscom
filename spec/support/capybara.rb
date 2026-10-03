require "capybara/rspec"

Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, :js, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
    # A janela é reaproveitada entre exemplos; volta ao tamanho de desktop.
    page.current_window.resize_to(1400, 900)
  end
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
