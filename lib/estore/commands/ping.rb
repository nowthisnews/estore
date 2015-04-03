module Estore
  module Commands
    class Ping
      include Command

      def call
        write('Ping')
        promise
      end

      def handle(*)
        promise.fulfill('Pong')
      end
    end
  end
end
