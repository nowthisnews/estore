module Estore
  module Commands
    class Ping
      include Command

      def call
        register!
        write('Ping')
        promise
      end

      def handle(*)
        remove!
        promise.fulfill('Pong')
      end
    end
  end
end
