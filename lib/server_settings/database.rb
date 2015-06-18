class ServerSettings
  class Database
    attr_accessor :name, :group, :master, :backup, :slaves, :settings
    def initialize(name, group)
      @name = name
      @group = group
    end

    def config(role)
      host = send(role)
      case host
      when Array
        host.map { |h| settings.merge(:host => h) }
      when String
        settings.merge(:host => host)
      else
        nil
      end
    end

    def host
      @master
    end

    def has_slave?
      !! @slaves and not @slaves.empty?
    end
  end
end
