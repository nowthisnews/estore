module Estore
  module Commands
    class ReadBatch
      include Command
      include Command::ReadStreamForward

      def initialize(connection, stream, from, limit)
        super(connection)
        @stream, @from, @limit = stream, from, limit
      end

      def call
        register!
        read(@stream, @from, @limit)
        promise
      end

      def handle(message, *)
        remove!
        response = decode(ReadStreamEventsCompleted, message)
        promise.fulfill(Array(response.events))
      end
    end
  end
end
