module Estore
  module Commands
    module Subscription
      def initialize(connection, stream, options = {})
        super(connection)
        @has_finished = false
        @stream = stream
        @resolve_link_tos = options.fetch(:resolve_link_tos, true)
        @worker_queue = Queue.new
        @worker = Thread.new { loop { worker_loop } }
      end

      def call
        start
      end

      def start
        raise 'Subscription block not defined' unless @handler

        msg = SubscribeToStream.new(
          event_stream_id: @stream,
          resolve_link_tos: @resolve_link_tos
        )

        register!
        write('SubscribeToStream', msg)
      end

      def close
        write('UnsubscribeFromStream', UnsubscribeFromStream.new)
        remove!
      end

      def on_event(&block)
        @handler = block
      end

      def enqueue(events)
        events = Array(events)
        @position = events.last.original_event_number
        @worker_queue << events
      end

      def worker_loop
        @worker_queue.pop.each { |event| @handler.call(event) }
      rescue => e
        puts e.message
        puts e.backtrace
      end
    end
  end
end
