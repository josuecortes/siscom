# Os contadores do rack-attack ficam em memória no teste; zera a cada exemplo.
RSpec.configure do |config|
  config.before { Rack::Attack.cache.store.clear }
end
