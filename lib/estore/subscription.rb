module Estore
  # Volatile Subscriptions
  #
  # This kind of subscription calls a given function for events written
  # after the subscription is established.
  #
  # For example, if a stream has 100 events in it when a subscriber connects,
  # the subscriber can expect to see event number 101 onwards until the time
  # the subscription is closed or dropped.
  class Subscription
    attr_reader :id, :stream, :resolve_link_tos, :position

    def initialize(estore, stream, options = {})
      @estore = estore
      @stream = stream
      @resolve_link_tos = options.fetch(:resolve_link_tos, true)
    end

    def on_error(&block)
      @on_error = block if block
    end

    def on_event(&block)
      @on_event = block if block
    end

    def start
      subscribe
    end

    def stop
      @estore.unsubscribe(id) if id
      @id = nil
    end

    private

    def subscribe
      prom = @estore.subscribe(stream, self, resolve_link_tos: resolve_link_tos)
      @id = prom.correlation_id
      prom.sync
    end

    def call_on_error(error)
      @on_error.call(error) if @on_error
    end

    def dispatch(event)
      @on_event.call(event) if @on_event
      @position = event.original_event_number
    end

    def event_appeared(event)
      dispatch(event)
    end
  end
end
