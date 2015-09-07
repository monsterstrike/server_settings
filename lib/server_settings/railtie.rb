class ServerSettings
  class Railtie < Rails::Railtie
    config.before_configuration do
      ServerSettings.load_config_dir("#{Rails.root}/config/servers/#{Rails.env}/*.yml")
    end
  end
end
