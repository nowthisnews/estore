module Estore
  module Commands
    class Append
      include Command

      handle WriteEventsCompleted => :completed

      def initialize(connection, stream, events, options = {})
        super(connection)
        @stream, @events, @options = stream, events, options
      end

      def call
        register!

        msg = WriteEvents.new(
          event_stream_id: @stream,
          expected_version: @options[:expected_version] || -2,
          events: Array(@events).map { |event| new_event(event) },
          require_master: true
        )
        write('WriteEvents', msg)

        promise
      end

      def completed(response)
        remove!

        if response.result == OperationResult::Success
          promise.fulfill(response)
        else
          promise.reject Estore::WriteEventsError.new(response)
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
    end
  end
end
