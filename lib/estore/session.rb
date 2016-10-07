require 'securerandom'

module Estore
  # The Session class is responsible for maintaining a full-duplex connection
  # between the client and the Event Store server.
  # An Estore session is thread-safe, and it is recommended to only have one
  # instance per application.
  #
  # All operations are handled fully asynchronously, returning a promise.
  # If you need to execute synchronously, simply call .sync on the returned
  # promise.
  #
  # To get maximum performance from the connection, it is recommended to use it
  # asynchronously.
  class Session
    extend Forwardable

    delegate [:host, :port] => :@connection

    def initialize(host, port = 2113)
      @connection = Connection.new(host, port)
    end

    def close
      @connection.close
    end

    def ping
      command(Commands::Ping).call
    end

    def read(stream, options = {})
      from = options[:from] || 0
      limit = options[:limit]

      if limit
        read_batch(stream, from, limit)
      else
        read_forward(stream, from)
      end
    end

    def read_batch(stream, from, limit)
      command(Commands::ReadBatch, stream, from, limit).call
    end

    def read_forward(stream, from, batch_size = nil, &block)
      command(Commands::ReadForward, stream, from, batch_size, &block).call
    end

    def append(stream, events, options = {})
      command(Commands::Append, stream, events, options).call
    end

    def subscription(stream, options = {})
      if options[:from]
        command(Commands::CatchUpSubscription, stream, options[:from], options)
      else
        command(Commands::LiveSubscription, stream, options)
      end
    end

    private

    def command(command, *args)
      command.new(@connection, *args)
    end
  end
end
