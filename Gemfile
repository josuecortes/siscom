source "https://rubygems.org"

ruby "3.4.5"

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Hotwire + Tailwind (sem Node)
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

# Solid Cache/Queue/Cable no banco principal
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "image_processing", "~> 1.2"

# Autenticação, autorização e segurança
gem "devise"
gem "pundit"
gem "rack-attack"

# Paginação e exportação
gem "pagy"
gem "caxlsx"
gem "caxlsx_rails"

# Monitoramento de erros
gem "rollbar"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false

  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.6"
end

group :development do
  gem "web-console"
end

group :test do
  gem "shoulda-matchers", "~> 7.0"
  gem "webmock", "~> 3.30"
  gem "simplecov", "~> 0.22.0", require: false
  gem "capybara"
  gem "selenium-webdriver"
end

# Notificações push (Web Push / VAPID)
gem "web-push"
