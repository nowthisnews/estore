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
          message = [error, "(stream '#{@stream}' does not exist?)"].join(' ')
          promise.reject ReadEventsError.new(message)
        else
          promise.fulfill(Array(response.events))
        end
      end
    end
  end
end
