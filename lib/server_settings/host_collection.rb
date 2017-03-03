class ServerSettings

  class HostCollection < Array
    attr_reader :role_config
    def initialize(hosts, role_config)
      @role_config = role_config
      unless hosts.kind_of?(Array)
        raise InvalidHosts, "hosts: #{hosts} is not array"
      end

      hosts.each do |host_exp|
        self.push Host.parse(host_exp)
      end
    end

    def with_format(format)
      self.map do |host|
        replacemap = @role_config
        replacemap['%host'] = host.host
        replacemap['%port'] = host.port if host.port
        replacemap.inject(format) do |string, mapping|
          string.gsub(*mapping)
        end
      end
    end

    # Errors
    class InvalidHosts < StandardError ; end

  end

end
