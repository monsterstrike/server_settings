class ServerSettings

  class Role
    attr_reader :name, :config

    def initialize(role, config)
      @name = role
      @config = load(config)
    end

    def load(config)
      if config.key?("hosts")
        hosts = config.delete("hosts")
        prop = config.dup
        config["hosts"]= HostCollection.new(hosts, prop)
      end
      config
    end

    def hosts
      @config["hosts"] if @config.has_key?("hosts")
    end

    def host
      hosts.first
    end

    def method_missing(name, *args, &block)
      key = name.to_s
      return nil unless @config.has_key? key
      @config[key]
    end

    def with_format(format)
      hosts.with_format(format)
    end

  end

end
