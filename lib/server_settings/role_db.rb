class ServerSettings
  class Database
    attr_accessor :name, :group, :master, :backup, :slaves, :settings
    def initialize(name, group)
      @name = name
      @group = group
    end

    def config(role)
      host = send(role)
      if host.kind_of?(Array)
        host.map { |h| settings.merge(:host => h) }
      elsif host.kind_of?(String)
        settings.merge(:host => host)
      else
        nil
      end
    end

    def has_slave?
      !! @slaves and not @slaves.empty?
    end
  end

  class RoleDB < Role
    include Enumerable
    attr_accessor :is_group

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

    def find(db_name)
      select { |s| s.name == db_name }.first
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
      each { |db| db.master }.flatten
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
