class ServerSettings

  class RoleDB < Role
    include Enumerable

    def databases
      @config.keys.select { |a| a.kind_of?(String) }
    end

    def build_db(name, config, group = nil)
      db = Database.new(name, group)
      db.master = config[:master]
      db.backup = config[:backup]
      db.slaves = config[:slaves]
      db.settings = config_params(config)
      return db
    end

    def find(db_name, db_group = nil)
      select { |s| s.name == db_name && s.group == db_group }.first
    end

    def each
      default_db = build_db("default", @config)
      yield default_db

      databases.each do |db_name|
        config = @config[db_name]

        if config && config.has_key?(:master)
          db = build_db(db_name, config)
          db.settings = default_db.settings.merge(db.settings)
          yield db

        else # this is group section
          group_name = db_name
          config.map do |nest_db_name, nest_config|
            db = build_db(nest_db_name, nest_config, group_name)
            db.settings = default_db.settings.merge(db.settings)
            yield db
          end
        end
      end
    end

    def hosts
      find_all
    end

    def config_params(config)
      exclude_settings = [ :master, :backup, :slaves ]
      config_keys = config.keys.select do |s|
        s.is_a?(Symbol) and not exclude_settings.include?(s)
      end
      Hash[*config_keys.map {|s| [s, config[s]] }.flatten]
    end

  end
end
