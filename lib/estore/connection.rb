module Estore
  # Connection owns the TCP socket, formats and sends commands over the socket.
  # It also starts a background thread to read from the TCP socket and handle
  # received packages, dispatching them to the calling app.
  class Connection
    extend Forwardable

    delegate [:register, :remove] => :@context

    def initialize(host, port, context)
      @host = host
      @port = Integer(port)
      @context = context
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

    def on_received_package(message, type, uuid, _flags)
      if type == 'HeartbeatRequestCommand'
        write(SecureRandom.uuid, 'HeartbeatResponseCommand')
      else
        @context.dispatch(uuid, message, type)
      end
    end

    def socket
      @socket || connect
    end

    def connect
      @socket = TCPSocket.open(@host, @port)
      Thread.new do
        process_downstream
      end
      @socket
    rescue TimeoutError, Errno::ECONNREFUSED, Errno::EHOSTDOWN,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ETIMEDOUT
      raise CannotConnectError, "Error connecting to Eventstore on "\
        "#{@host.inspect}:#{@port.inspect} (#{$ERROR_INFO.class})"
    end

    def process_downstream
      loop do
        @buffer << socket.sysread(4096)
      end
    rescue IOError, EOFError
      on_disconnect
    rescue => error
      on_exception(error)
    end

    def on_disconnect
      return if @terminating
      puts 'Eventstore disconnected'
      context.on_error(DisconnectionError.new('Eventstore disconnected'))
    end

    def on_exception(error)
      puts "process_downstream_error"
      puts error.message
      puts error.backtrace
      @context.on_error(error)
    end
  end
end
