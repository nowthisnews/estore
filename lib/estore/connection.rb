module Estore
  # Connection owns the TCP socket, formats and sends commands over the socket.
  # It also starts a background thread to read from the TCP socket and handle
  # received packages, dispatching them to the calling app.
  class Connection
    extend Forwardable

    attr_reader :host, :port
    delegate [:register, :remove] => :@context

    def initialize(host, port)
      @host = host
      @port = Integer(port)
      @context = ConnectionContext.new
      @buffer = Buffer.new(&method(:on_received_package))
      @mutex = Mutex.new
    end

    def close
      @terminating = true
      socket.close
    end

    def write(uuid, command, msg = nil)
      msg.validate! if msg

      code = COMMANDS.fetch(command)
      frame = Package.encode(code, uuid, msg)

      @mutex.synchronize do
        socket.write(frame.to_s)
      end
    end

    private

    def on_received_package(type, package, uuid, _flags)
      if type == 'HeartbeatRequestCommand'
        write(SecureRandom.uuid, 'HeartbeatResponseCommand')
      else
        @context.dispatch(uuid, Package.decode(type, package))
      end
    end

    def socket
      @socket || connect
    end

    def connect
      @socket = TCPSocket.open(@host, @port)
      Thread.new { process_downstream }
      @socket
    rescue TimeoutError, Errno::ECONNREFUSED, Errno::EHOSTDOWN,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ETIMEDOUT
      raise CannotConnectError, "#{@host}:#{@port} (#{$ERROR_INFO.class})"
    end

    def process_downstream
      loop { @buffer << socket.sysread(4096) }
    rescue IOError, EOFError
      @context.on_error(DisconnectionError.new) unless @terminating
    rescue => error
      @context.on_error(error)
    end
  end
end
