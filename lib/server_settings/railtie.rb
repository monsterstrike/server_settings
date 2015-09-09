class ServerSettings
  class Railtie < Rails::Railtie
    rake_tasks do
      load "server_settings/tasks/db.rake"
    end
  end
end
