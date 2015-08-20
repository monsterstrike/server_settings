class ServerSettings
  class DatabaseConfig
    def self.slave_name(name, idx)
      name + "_slave#{idx}"
    end

    def self.generate_database_config(db_role, with_slave:true)
      configuration = {}
      return configuration unless ServerSettings.databases

      ServerSettings.databases.each do |db|
        next unless db.config(db_role)

        db_config = db.config(db_role)
        stringify_keys!(db_config) if defined? Rails

        if db.name == "default"
          if defined? Rails
            configuration[Rails.env] = db_config
          else
            configuration.merge!(db_config)
          end
        elsif db.group
          configuration[db.group] ||= {}
          configuration[db.group][db.name] = db_config
        else
          configuration[db.name] = db_config
        end

        if with_slave && db.has_slave?
          db.config(:slaves).each.with_index(1) do |config, idx|
            # スレーブのバックアップホストは、マスターのバックアップホストと同じにする
            config[:host] = db.backup if db_role == :backup
            stringify_keys!(config) if defined? Rails
            configuration[slave_name(db.name, idx)] = config
          end
        end
      end
      configuration
    end

    def self.stringify_keys!(config)
      config.keys.each { |key| config[key.to_s] = config.delete(key) }
    end
  end
end
