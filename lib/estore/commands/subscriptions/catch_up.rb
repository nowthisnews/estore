module Estore
  module Commands
    class CatchUpSubscription
      include Command
      include Subscription

      handle StreamEventAppeared => :event_appeared,
             SubscriptionConfirmation => :ignore

      def initialize(connection, stream, from, options = {})
        super(connection, stream, options)
        @from = from
        @batch = options[:batch_size]
        @mutex = Mutex.new
        @while_catching_up = []
        @caught_up = false
      end

      def start
        super

        # TODO: Think about doing something more clever?
        read = ReadForward.new(@connection, @stream, @from, @batch) do |events|
          enqueue events unless events.empty?
        end

        read.call.sync
        switch_to_live
      end

      def switch_to_live
        @mutex.synchronize do
          unprocessed_events.each { |event| enqueue event }
          @caught_up = true
        end
      end

      def unprocessed_events
        @while_catching_up.find_all { |event| event.original_event_number > @position }
      end

      def event_appeared(response)
        unless @caught_up
          @mutex.synchronize do
            @while_catching_up << response.event unless @caught_up
          end
        end

        enqueue response.event if @caught_up
      end
    end
  end
end
