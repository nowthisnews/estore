module Estore
  module Commands
    class ReadForward
      include Command
      include Command::ReadStreamForward

      def initialize(connection, stream, from, batch_size = nil, &block)
        super(connection)

        @stream = stream
        @from = from
        @batch_size = batch_size || 1000
        @block = block
        @events = []
      end

      def call
        register!
        read(@stream, @from, @batch_size)
        promise
      end

      def handle(message, *)
        response = decode(ReadStreamEventsCompleted, message)
        events = Array(response.events)

        @from += events.size
        read(@stream, @from, @batch_size) unless response.is_end_of_stream

        @block ? @block.call(events) : @events.push(*events)

        if response.is_end_of_stream
          remove!
          promise.fulfill(@block ? nil : @events)
        end
      end
    end
  end
end
