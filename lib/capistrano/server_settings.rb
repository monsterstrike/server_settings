require 'server_settings'

def load_servers(pattern)
  ServerSettings.load_config_dir(pattern)
  ServerSettings.each_role do |role, hosts|
    role role.to_sym, *hosts.map(&:host)
  end
end
