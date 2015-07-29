module DatabaseConfig

  def self.slave_name(name, idx)
    name + "_slave#{idx}"
  end

  def self.generate_database_config(db_role, with_slave:true)
    configuration = {}
    return configuration unless ServerSettings.databases

    ServerSettings.databases.each do |db|
      next unless db.config(db_role)

      if db.name == "default"
        if defined? Rails
          configuration[Rails.env] = db.config(db_role)
        else
          configuration.merge!(db.config(db_role))
        end
      elsif db.group
        configuration[db.group] ||= {}
        configuration[db.group][db.name] = db.config(db_role)
      else
        configuration[db.name] = db.config(db_role)
      end

      if with_slave && db.has_slave?
        db.config(:slaves).each.with_index(1) do |config, idx|
          # スレーブのバックアップホストは、マスターのバックアップホストと同じにする
          config[:host] = db.backup if db_role == :backup
          configuration[slave_name(db.name, idx)] = config
        end
      end
    end
    configuration
  end
end
