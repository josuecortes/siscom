require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Siscom
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    I18n.config.available_locales = :'pt-BR'
    config.i18n.default_locale = :'pt-BR'
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml')]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.time_zone = "Brasilia"
    config.active_record.default_timezone = :local # Or :utc

    # Diferent layouts to devise
    config.to_prepare do
      Devise::SessionsController.layout "devise"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "application" : "devise" }
      Devise::ConfirmationsController.layout "devise"
      Devise::UnlocksController.layout "devise"
      Devise::PasswordsController.layout "devise"
    end
  end
end
