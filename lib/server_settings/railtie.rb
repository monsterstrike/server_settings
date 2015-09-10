class ServerSettings
  class Railtie < Rails::Railtie
    rake_tasks do
      load "server_settings/tasks/db.rake"
    end
    config.before_configuration do
      ServerSettings.load_config_dir("#{Rails.root}/config/servers/#{Rails.env}/*.yml")
    end
  end
end
