require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module Siscom
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.available_locales = [ :"pt-BR", :en ]
    config.i18n.default_locale = :"pt-BR"
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.{rb,yml}")]

    # O banco de produção grava datas no horário local (Brasília).
    # Não trocar para :utc sem migrar todos os timestamps existentes.
    config.time_zone = "Brasilia"
    config.active_record.default_timezone = :local

    config.to_prepare do
      Devise::SessionsController.layout "publico"
      Devise::PasswordsController.layout "publico"
    end

    config.generators do |g|
      g.test_framework :rspec
      g.system_tests nil
    end
  end
end
