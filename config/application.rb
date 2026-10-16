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

    # O banco guarda data e hora em UTC (é assim que produção sempre gravou: o servidor
    # roda em UTC). A tela mostra no horário do Amapá (UTC-3, sem horário de verão).
    # Fixar :utc aqui evita depender do fuso da máquina onde o sistema roda.
    config.time_zone = "America/Belem"
    config.active_record.default_timezone = :utc

    # Catálogos dos módulos (permissões, papéis, menu): recarregar ao editar em desenvolvimento.
    config.watchable_dirs[Rails.root.join("config/modulos").to_s] = [ :yml ]

    config.generators do |g|
      g.test_framework :rspec
      g.system_tests nil
    end
  end
end
