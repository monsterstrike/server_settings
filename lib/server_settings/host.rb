class ServerSettings
  class Host
    attr_accessor :host, :port, :opt

    def initialize(host, port, opt = {})
      @host = host
      @port = port

      @host = opt.delete("host") if opt.key?("host")
      @port = opt.delete("port") if opt.key?("port")
      @opt = opt
    end

    def to_h
      basic = Hash.new
      basic["host"] = host if host
      basic["port"] = port if port
      if opt
        opt.merge(basic)
      else
        basic
      end
    end

    class << self
      def parse(host_line)
        case host_line
        when String
          host, port = host_line.split(/:/)
          new(host, port)
        when Hash
          new(nil, nil, host_line)
        end
      end
    end
  end
end
