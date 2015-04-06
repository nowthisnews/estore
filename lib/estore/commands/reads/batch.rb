module Estore
  module Commands
    class ReadBatch
      include Command
      include ReadStreamForward

      handle ReadStreamEventsForwardCompleted => :completed

      def initialize(connection, stream, from, limit)
        super(connection)
        @stream, @from, @limit = stream, from, limit
      end

      def call
        register!
        read(@stream, @from, @limit)
        promise
      end

      def completed(response)
        remove!
        error = error(response)

        if error
          promise.reject error
        else
          promise.fulfill(Array(response.events))
        end
      end
    end
  end
end
