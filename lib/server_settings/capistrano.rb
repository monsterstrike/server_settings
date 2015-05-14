require 'server_settings'

module Capistrano
  module ServersGroup
    def self.extend(configuration)
      configuration.load do
        Capistrano::Configuration.instance.load do
          def load_servers(filename)
            ServerSettings.load_config(filename)
            ServerSettings.each_role do |role, hosts|
              role role.to_sym, *hosts
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::ServersGroup.extend(Capistrano::Configuration.instance)
end

