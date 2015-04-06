module Estore
  module Commands
    module Command
      attr_reader :uuid

      def self.included(base)
        base.extend ClassMethods
        base.singleton_class.class_eval { attr_accessor :handlers }
        base.handlers = {}
      end

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

      def reject!(error)
        @promise.reject(error) if @promise
      end

      def write(command, message = nil)
        @connection.write(@uuid, command, message)
      end

      def promise
        @promise ||= Promise.new(@uuid)
      end

      def handle(message)
        handler = self.class.handlers[message.class]

        if handler
          send(handler, message) unless handler == :ignore
        else
          $stderr.puts "#{message.class} arrived but not handled by "\
            "command #{self.class}"
        end
      end

      module ClassMethods
        def handle(hash)
          handlers.update(hash)
        end
      end
    end
  end
end
