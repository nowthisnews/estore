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
        @queue = []
        @caught_up = false
        @last_worker = nil
      end

      def start
        super

        # TODO: Think about doing something more clever?
        read = ReadForward.new(@connection, @stream, @from, @batch) do |events|
          @last_worker = Thread.new(@last_worker) do |last_worker|
            last_worker.join if last_worker
            events.each { |event| dispatch(event) }
          end
        end

        read.call.sync
        @last_worker.join if @last_worker

        switch_to_live
      end

      def switch_to_live
        @mutex.synchronize do
          queued_events.each { |event| dispatch(event) }
          @caught_up = true
        end
      end

      def queued_events
        @queue.find_all { |event| event.original_event_number > @position }
      end

      def event_appeared(response)
        unless @caught_up
          @mutex.synchronize do
            @queue << response.event unless @caught_up
          end
        end

        dispatch(response.event) if @caught_up
      end
    end
  end
end
