module Estore
  module Commands
    module Command
      attr_reader :uuid

      def initialize(connection)
        @connection = connection
        @uuid = SecureRandom.uuid
      end

      def register!
        @connection.register(self)
      end

      def remove!
        @connection.remove(self)
      end

      def write(command, message = nil)
        @connection.write(@uuid, command, message)
      end

      def promise
        @promise ||= Promise.new(@uuid)
      end

      def decode(type, message)
        type.decode(message)
      rescue => error
        puts "Protobuf decoding error on connection #{object_id}"
        puts type: type, message: message
        puts error.backtrace
        raise error
      end

      module ReadStreamForward
        def read(stream, from, limit)
          msg = ReadStreamEvents.new(
            event_stream_id: stream,
            from_event_number: from,
            max_count: limit,
            resolve_link_tos: true,
            require_master: false
          )

          write('ReadStreamEventsForward', msg)
        end
      end
    end
  end
end
