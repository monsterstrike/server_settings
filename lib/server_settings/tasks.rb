class ServerSettings
  module Task
    def self.load_rake
      spec = Gem::Specification.find_by_name "server_settings"
      load "#{spec.gem_dir}/lib/server_settings/tasks/db.rake"
    end
  end
end
ServerSettings::Task.load_rake
