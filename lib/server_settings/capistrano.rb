require 'server_settings'

module Capistrano
  module ServersGroup
    def self.extend(configuration)
      configuration.load do
        Capistrano::Configuration.instance.load do
          def load_servers(pattern)
            ServerSettings.load_config_dir(pattern)
            ServerSettings.each_role do |role, hosts|
              if hosts.class == ::ServerSettings::HostCollection
                role_properties              = {}
                role_properties[:no_release] = true if hosts.properties["%no_release"]
                role_properties[:primary]    = true if hosts.properties["%primary"]
                role_properties[:active]     = true if hosts.properties["%active"]
                role role.to_sym, *hosts.map(&:host), role_properties
              else
                role role.to_sym, *hosts.map(&:host).shuffle
              end
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

