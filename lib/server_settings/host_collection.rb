class ServerSettings

  class HostCollection < Array
    attr_reader :properties
    def initialize(hosts, properties)
      @properties = properties
      unless hosts.kind_of?(Array)
        raise InvalidHosts, "hosts: #{hosts} is not array"
      end

      hosts.each do |host_exp|
        self.push Host.parse(host_exp)
      end
    end

    def with_format(format)
      self.map do |h|
        host = @properties.merge(h.to_h)
        replacemap = @properties.inject({}) { |a, (k, v)| a["%#{k}"] = v.to_s; a }
        replacemap['%host'] = host["host"]
        replacemap['%port'] = host["port"].to_s if host["port"]
        replacemap.inject(format) do |string, mapping|
          string.gsub(*mapping)
        end
      end
    end

    def with_hash
      map { |host| @properties.merge(host.to_h) }
    end

    # Errors
    class InvalidHosts < StandardError ; end

  end

end
