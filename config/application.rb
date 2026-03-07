require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module KingsLendas
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])
    config.generators.system_tests = nil

    # Timezone: São Paulo (UTC-3)
    config.time_zone = "America/Sao_Paulo"
    config.active_support.default_locale = :"pt-BR"

    # Cache store configured per environment (memory in dev, redis in prod)

    # Autoload initializers
    config.autoload_paths += [ "#{root}/app/services", "#{root}/app/structs" ]
  end
end
