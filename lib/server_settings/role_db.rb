class ServerSettings
  class RoleDB < Role

    def databases
      @config.keys.select { |a| a.kind_of?(String) }
    end

    def db_config_each
      databases.map do |db|
        config = @config[db]
        if config && config.has_key?(:host)
          yield(config)
        else
          config.map do |nest_db, nest_config|
            yield(nest_config)
          end
        end
      end
    end

    def hosts
      db_config_each do |config|
        config[:host]
      end.flatten
    end

    # database.rb data strcutre
    def configurations
      parent_config_keys = @config.keys.select {|s| s.is_a?(Symbol)}
      parent_config = Hash[*parent_config_keys.map {|s| [s, @config[s]] }.flatten]
      db_config_each do |config|
        parent_config.each do |key,value|
          next if config.has_key?(key)
          config[key] = value
        end
      end
      return @config
    end

  end
end

