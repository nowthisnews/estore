require 'promise'

module Estore
  # Registry storing handlers for the pending commands
  class ConnectionContext
    def initialize
      @mutex = Mutex.new
      @commands = {}
    end

    def register(command)
      @mutex.synchronize do
        @commands[command.uuid] = command
      end
    end

    def remove(command)
      @mutex.synchronize do
        @commands.delete(command.uuid)
      end
    end

    def dispatch(uuid, message, type)
      command = @commands[uuid]
      command.handle(message, type) if command
    end

    def on_error(error)
      # TODO: Error handling
      @mutex.synchronize do
        @commands.each { |_uuid, command| command.reject! error }
      end
    end
  end
end
