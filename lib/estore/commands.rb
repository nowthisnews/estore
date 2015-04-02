module Estore
  module Commands
    class Promise < ::Promise
      attr_reader :correlation_id

      def initialize(correlation_id)
        super()
        @correlation_id = correlation_id
      end

      def wait
        t = Thread.current
        resume = proc { t.wakeup }
        self.then(resume, resume)
        sleep
      end
    end

    module Command
      attr_reader :uuid

      def initialize(connection)
        @connection = connection
        @uuid = SecureRandom.uuid
      end

      def finished?
        @promise.nil? or @promise.fulfilled?
      end

      def write(command, message=nil)
        @connection.write(@uuid, command, message)
      end

      def promise
        @promise ||= Promise.new(@uuid)
      end

      def handle(message)
        promise.fulfill(decode(message))
      end

      def decode(message)
        response_type.decode(message)
      rescue => error
        puts "Protobuf decoding error on connection #{object_id}"
        puts error.inspect
        p type: type, message: message
        puts "\n\n"
        puts(*error.backtrace)
        raise error
      end

      module ReadStream
        def read(stream, from, limit)
          msg = ReadStreamEvents.new(
            event_stream_id: stream,
            from_event_number: from,
            max_count: limit,
            resolve_link_tos: true,
            require_master: false
          )

          write('ReadStreamEventsForward', msg)
        end
      end
    end

    class Ping
      include Command

      def call
        write('Ping')
        promise
      end

      def handle(_message)
        promise.fulfill('Pong')
      end
    end

    class ReadBatch
      include Command
      include Command::ReadStream

      def initialize(connection, stream, from, limit)
        super(connection)
        @stream, @from, @limit = stream, from, limit
      end

      def call
        read(@stream, @from, @limit)
        promise
      end

      def response_type
        ReadStreamEventsCompleted
      end

      def handle(message)
        promise.fulfill(Array(decode(message).events))
      end
    end

    class ReadForward
      include Command
      include Command::ReadStream

      def initialize(connection, stream, from, batch_size = nil, &block)
        super(connection)

        @stream = stream
        @from = from
        @batch_size = batch_size || 100
        @block = block
        @events = []
      end

      def call
        read(@stream, @from, @batch_size)
        promise
      end

      def handle(message)
        response = decode(message)
        events = Array(response.events)

        @from += events.size
        read(@stream, @from, @batch_size) unless response.is_end_of_stream

        if @block
          block.call(events)
        else
          @events.push(*events)
        end

        promise.fulfill(@block ? nil : @events) if response.is_end_of_stream
      end

      def response_type
        ReadStreamEventsCompleted
      end
    end

    class Append
      include Command

      CONTENT_TYPES = {
        json: 1
      }

      def initialize(connection, stream, events, options = {})
        super(connection)
        @stream, @events, @options = stream, events, options
      end

      def call
        msg = WriteEvents.new(
          event_stream_id: @stream,
          expected_version: @options[:expected_version] || -2,
          events: Array(@events).map { |event| new_event(event) },
          require_master: true
        )

        write('WriteEvents', msg)
        promise
      end

      def handle(message)
        response = decode(message)

        if response.result != OperationResult::Success
          # TODO: Create custom exceptions
          raise "WriteEvents command failed with uuid #{@uuid}"
        end

        promise.fulfill(response)
      end

      def response_type
        WriteEventsCompleted
      end

      private

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
    end
  end
end
