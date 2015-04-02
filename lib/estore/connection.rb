module Estore
  # Connection owns the TCP socket, formats and sends commands over the socket.
  # It also starts a background thread to read from the TCP socket and handle
  # received packages, dispatching them to the calling app.
  class Connection
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

    def command(command)
      result = command.call
      @context.register(command) unless command.finished?
      result
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

    def on_received_package(command, message, uuid, _flags)
      if command == 'HeartbeatRequestCommand'
        write(SecureRandom.uuid, 'HeartbeatResponseCommand')
      else
        @context.dispatch(uuid, message)
      end

      #case command
      #when 'Pong'
      #  context.fulfill(uuid, 'Pong')
      #when 'HeartbeatRequestCommand'
      #  send_command('HeartbeatResponseCommand')
      #when 'SubscriptionConfirmation'
      #  context.fulfill(uuid, decode(SubscriptionConfirmation, message))
      #when 'ReadStreamEventsForwardCompleted'
      #  context.fulfill(uuid, decode(ReadStreamEventsCompleted, message))
      #when 'StreamEventAppeared'
      #  resolved_event = decode(StreamEventAppeared, message).event
      #  context.trigger(uuid, :event_appeared, resolved_event)
      #when 'WriteEventsCompleted'
      #  on_write_events_completed(uuid, decode(WriteEventsCompleted, message))
      #else
      #  raise command
      #end
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
      puts "process_downstream_error #{error.inspect}"
      @context.on_error(error)
    end
  end
end
