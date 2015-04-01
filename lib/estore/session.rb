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
    attr_reader :host, :port, :connection, :context

    def initialize(host, port = 2113)
      @host = host
      @port = port
      @context = ConnectionContext.new
      @connection = Connection.new(host, port, context)
    end

    def on_error(error = nil, &block)
      context.on_error(error, &block)
    end

    def close
      connection.close
    end

    def ping
      command('Ping')
    end

    def read(stream, start, limit)
      msg = ReadStreamEvents.new(
        event_stream_id: stream,
        from_event_number: start,
        max_count: limit,
        resolve_link_tos: true,
        require_master: false
      )

      command('ReadStreamEventsForward', msg)
    end

    def append(stream, events, options = {})
      msg = WriteEvents.new(
        event_stream_id: stream,
        expected_version: options[:expected_version] || -2,
        events: Array(events).map { |event| new_event(event) },
        require_master: true
      )

      command('WriteEvents', msg)
    end

    def subscribe(stream, handler, options = {})
      msg = SubscribeToStream.new(
        event_stream_id: stream,
        resolve_link_tos: options[:resolve_link_tos]
      )

      command('SubscribeToStream', msg, handler)
    end

    def subscription(stream, options = {})
      if options[:catch_up_from]
        CatchUpSubscription.new(self, stream, options[:catch_up_from], options)
      else
        Subscription.new(self, stream, options)
      end
    end

    private

    CONTENT_TYPES = {
      json: 1
    }

    def new_event(event)
      uuid = event[:id] || SecureRandom.uuid
      content_type = event.fetch(:content_type, :json)

      NewEvent.new(
        event_id: Package.encode_uuid(uuid),
        event_type: event[:type],
        data: event[:data],
        data_content_type: CONTENT_TYPES.fetch(content_type, 0),
        metadata_content_type: 1
      )
    end

    def command(*args)
      connection.send_command(*args)
    end
  end
end
