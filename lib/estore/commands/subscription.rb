module Estore
  module Commands
    class Subscription
      include Command

      def initialize(connection, stream, options = {})
        super(connection)
        @has_finished = false
        @stream = stream
        @resolve_link_tos = options.fetch(:resolve_link_tos, true)
      end

      def finished?
        @has_finished
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

      def handle(message, type)
        dispatch(decode(StreamEventAppeared, message).event) if
          type == 'StreamEventAppeared'
      end

      def dispatch(event)
        @position = event.original_event_number
        @handler.call(event)
      end
    end
  end
end
