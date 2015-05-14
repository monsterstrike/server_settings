class ServerSettings

  class Host
    attr_accessor :host, :port
    def initialize(host,port)
      @host = host
      @port = port
    end

    def self.parse(host_line)
      host, port = host_line.split(/:/)
      self.new(host,port)
    end
  end

end
